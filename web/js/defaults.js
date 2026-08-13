// ═══════════════════════════════════════════════════════
// § 01B · FIXED REFERENCE DATA (season config, not user state)
// ═══════════════════════════════════════════════════════
// Everything in this file is constant configuration for the current FLL
// season — it never changes at runtime. Actual team state (the live
// checklist, scores, logs, etc.) lives in web/js/state.js.

// Starter checklist seeded for a brand-new team (state.checklist after
// this point is normal mutable state — items can be added/removed/checked).
const DEFAULT_CHECKLIST = [
  { id: 1, text: 'ארגז כלים מוכן', done: false },
  { id: 2, text: 'סוללות טעונות', done: false },
  { id: 3, text: 'פוסטר פרויקט מודפס', done: false },
  { id: 4, text: 'תיקיית שיפוט מוכנה', done: false },
  { id: 5, text: 'זרועות ורובוט ארוזים', done: false },
];

// Official FLL Unearthed 2026 missions (source: FIRST Israel scorer)
const MISSIONS_2026 = [
  { id: 1,  name: 'M01 – ציוד הגנה', pts: 20 },
  { id: 2,  name: 'M02 – בית הגידול', pts: 20 },
  { id: 3,  name: 'M03 – ניטור מים', pts: 20 },
  { id: 4,  name: 'M04 – דגימת ליבה', pts: 20 },
  { id: 5,  name: 'M05 – שחרור עץ', pts: 25 },
  { id: 6,  name: 'M06 – הזזת מכון קידוח', pts: 25 },
  { id: 7,  name: 'M07 – משאבה', pts: 25 },
  { id: 8,  name: 'M08 – שחרור אבנים', pts: 20 },
  { id: 9,  name: 'M09 – אנרגיה סולארית', pts: 25 },
  { id: 10, name: 'M10 – אוורור מרחב', pts: 20 },
  { id: 11, name: 'M11 – כלי עבודה', pts: 20 },
  { id: 12, name: 'M12 – מכונת קידוח', pts: 30 },
  { id: 13, name: 'M13 – הרים חומר', pts: 25 },
  { id: 14, name: 'M14 – פינוי', pts: 20 },
  { id: 15, name: 'M15 – נקודת ציון', pts: 20 },
];

// Official FLL Unearthed 2026 rubrics (FIRST Israel judging criteria)
const OFFICIAL_RUBRICS = {
  values: [
    'גילוי – הצוות מחפש מידע חדש ומשתף ממצאים בשמחה',
    'חדשנות – הצוות משתמש בחשיבה יצירתית לפתרון בעיות',
    'השפעה – הצוות מבין שעבודתו משפיעה לטובה על הסביבה',
    'שילוב – הצוות מכיל ומכבד את כל חברי הקהילה',
    'עבודת צוות – כל חברי הצוות תורמים ותומכים אחד בשני',
    'כיף – הצוות נהנה מהתהליך כולו ומעורר הנאה בסביבתו',
    'ערכים בפועל – הצוות מפגין את ערכי FLL בכל אינטראקציה בתחרות',
  ],
  robot: [
    'זיהוי בעיה – הצוות מגדיר בבהירות את אתגר המשימה לפני הפתרון',
    'תכנון – הצוות מתעד תוכניות וסקיצות לפני הבנייה',
    'בנייה – הרובוט בנוי בצורה יציבה ועומד בדרישות הגודל',
    'שיפור איטרטיבי – הצוות מתעד לפחות 3 גרסאות שיפור לכל זרוע',
    'תכנות – הקוד מאורגן, מוסבר ומציג בקרת תנועה אמינה',
    'שת"פ קוד-מכניקה – יש קשר ברור בין תכנות לעיצוב מכני',
    'ביצוע – הרובוט מבצע לפחות 8 משימות בריצה אחת',
  ],
  innovation: [
    'בעיה ממוקדת – הצוות מגדיר בבהירות בעיה אמיתית הקשורה לחציבה/עפר',
    'מחקר – הצוות אסף מידע ממקורות מגוונים ומומחים',
    'ראיונות – הצוות ראיין לפחות 3 בעלי עניין או מומחים',
    'פתרון מקורי – הרעיון הוא מקורי ולא קיים בשוק',
    'הנחיה – הצוות שיתף את הפתרון עם מומחים וקיבל משוב',
    'ישימות – הפתרון ניתן לביצוע עם משאבים סבירים',
    'שיתוף – הצוות הציג את הפתרון לקהילה רחבה',
  ],
};
