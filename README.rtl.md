# Claude Code עם עברית RTL על Windows

הפעלת Claude Code על Windows עם תצוגת עברית מימין לשמאל. בלי WSL. בלי שרת מרוחק. רק Git Bash.

## הבעיה

CMD ו-PowerShell לא תומכים ב-BiDi. עברית מוצגת הפוך ולא קריאה.

## הפתרון

Git Bash (mintty) תומך ב-BiDi באופן מובנה. הסקריפט מגדיר הכל בפקודה אחת.

## דרישות מוקדמות

- Windows 10/11
- Git for Windows מותקן (כולל Git Bash + mintty)
- Node.js מותקן
- Claude Code: `npm install -g @anthropic-ai/claude-code`

## התקנה מהירה

פותחים Git Bash ומריצים:

```bash
git clone https://github.com/NatiLevyy/claude-code-hebrew-rtl.git
cd claude-code-hebrew-rtl
bash setup.sh
```

או בלי clone:

```bash
curl -fsSL https://raw.githubusercontent.com/NatiLevyy/claude-code-hebrew-rtl/main/setup.sh | bash
```

## מה הסקריפט עושה

| קובץ | תפקיד |
|------|--------|
| `~/.bashrc` | מוסיף את npm ל-PATH כדי ש-Git Bash ימצא את claude. מגדיר locale עברי. |
| `~/.bash_profile` | טוען את bashrc ב-login shell. בלי זה קיצורי הדרך לא מוצאים את claude. |
| `~/.minttyrc` | מפעיל BiDi rendering, מגדיר locale עברי ו-UTF-8. |
| קיצורי דרך | "Claude Code (Hebrew)" מפעיל Claude ישירות. "Git Bash Hebrew" פותח טרמינל. |

כל קובץ קיים מגובה לפני שינוי.

## שלוש ההגדרות הקריטיות

ב-`~/.minttyrc`:

```ini
Locale=he_IL
Charset=UTF-8
BidiRendering=1
```

שלוש שורות אלה הן מה שגורם לעברית להופיע RTL כמו שצריך ב-mintty.

## התקנה ידנית

אם מעדיפים להגדיר ידנית במקום להריץ את הסקריפט:

1. להוסיף ל-`~/.bashrc`:
   ```bash
   export PATH="$PATH:$APPDATA/npm"
   export LANG=he_IL.UTF-8
   export LC_ALL=he_IL.UTF-8
   ```

2. להוסיף ל-`~/.bash_profile`:
   ```bash
   if [ -f ~/.bashrc ]; then . ~/.bashrc; fi
   ```

3. ליצור `~/.minttyrc`:
   ```ini
   Font=Consolas
   FontHeight=12
   Locale=he_IL
   Charset=UTF-8
   BidiRendering=1
   Term=xterm-256color
   ```

4. לפתוח Git Bash ולהריץ `claude`.

## למה mintty?

| טרמינל | תמיכת BiDi | עברית RTL |
|--------|-------------|-----------|
| CMD | לא | שבור |
| PowerShell | לא | שבור |
| Windows Terminal | חלקית | לא עקבי |
| **mintty (Git Bash)** | **כן** | **עובד** |

ל-mintty יש BiDi rendering מובנה. בלי תוספים, בלי workarounds.

## רישיון

MIT
