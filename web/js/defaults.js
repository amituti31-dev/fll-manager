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

// Official FIRST Israel judging rubrics (fll-events.firstisrael.org.il/tools/rubrics,
// rubric version 2025-11-23): each criterion has the official text for the first
// three levels (the 4th, "מצטיינת", has no text — judges just mark it).
// coreValues: true = the official rubric counts this criterion toward core values too;
// the core-values tab is just those criteria, sharing the same marks.
const RUBRIC_GRID = {
  innovation: { title: "פרויקט החדשנות", sections: [
    { id: 'identify', title: "זיהוי",
      description: "הקבוצה הגדירה את הבעיה באופן ברור וחקרה אותה היטב.",
      fields: [
        { id: 'problem', coreValues: false, levels: ["הגדרת הבעיה אינה ברורה", "הגדרת הבעיה ברורה באופן חלקי", "הגדרת הבעיה ברורה"] },
        { id: 'research', coreValues: true, levels: ["עדות מינימלית למחקר", "עדות חלקית למחקר על סמך מקור אחד או יותר", "מחקר ברור ומפורט על סמך מגוון מקורות מידע"] },
      ] },
    { id: 'design', title: "תכנון",
      description: "הקבוצה בנתה ביחד את תוכנית הפרויקט ופיתחה ביחד את רעיונותיה.",
      fields: [
        { id: 'plan', coreValues: false, levels: ["עדות מינימלית לתוכנית עבודה תכליתית", "עדות חלקית לתוכנית עבודה תכליתית", "עדות ניכרת לתוכנית עבודה תכליתית"] },
        { id: 'participation', coreValues: true, levels: ["עדות מינימלית שכל חברי הקבוצה השתתפו בתהליך הפיתוח", "עדות חלקית שכל חברי הקבוצה השתתפו בתהליך הפיתוח", "עדות ניכרת שכל חברי הקבוצה השתתפו בתהליך הפיתוח"] },
      ] },
    { id: 'create', title: "יצירה",
      description: "הקבוצה פיתחה רעיון מקורי או התבססה על אחד קיים, תוך הכנת דגם או סרטוט של אב־טיפוס לשם הצגת הפתרון.",
      fields: [
        { id: 'innovation', coreValues: true, levels: ["הסבר מינימלי של חדשנות הפתרון", "הסבר פשטני של חדשנות הפתרון", "הסבר מפורט של חדשנות הפתרון"] },
        { id: 'model', coreValues: false, levels: ["דגם או סרטוט של הפתרון אינו ברור", "דגם או סרטוט פשוט של הפתרון", "דגם או סרטוט מפורט של הפתרון"] },
      ] },
    { id: 'iterate', title: "חזרה ושינוי",
      description: "הקבוצה שיתפה את הרעיונות שלה, אספה משובים ובעקבותיהם שילבה שיפורים בפתרון.",
      fields: [
        { id: 'share', coreValues: false, levels: ["שיתוף מינימלי של הפתרון עם אחרים", "הפתרון שותף עם לפחות אדם אחד או קבוצה אחת", "הפתרון שותף עם אנשים רבים או קבוצות רבות"] },
        { id: 'improve', coreValues: false, levels: ["עדות מינימלית לשיפורים על סמך המשוב", "עדות חלקית לשיפורים על סמך המשוב", "עדות ניכרת לשיפורים על סמך המשוב"] },
      ] },
    { id: 'communicate', title: "הצגה",
      description: "הקבוצה שיתפה במצגת תכליתית את הפתרון שלה ואת השפעתו על אחרים, וחגגה את ההתקדמות שלה.",
      fields: [
        { id: 'explanation', coreValues: true, levels: ["הסבר הפתרון והשפעתו האפשרית על אחרים אינם ברורים", "הסבר הפתרון והשפעתו האפשרית על אחרים ברורים חלקית", "הסבר הפתרון והשפעתו האפשרית על אחרים ברורים לחלוטין"] },
        { id: 'pride', coreValues: true, levels: ["הקבוצה מדגימה גאווה או התלהבות באופן מינימלי", "הקבוצה מדגימה גאווה או התלהבות באופן חלקי", "הקבוצה מדגימה גאווה או התלהבות באופן ניכר"] },
      ] },
  ] },
  robot: { title: "תכנון הרובוט", sections: [
    { id: 'identify', title: "זיהוי",
      description: "הקבוצה הגדירה אילו משימות תנסה לפתור, חקרה משאבים של בנייה ותכנות ונעזרה בהנחייה על פי הצורך.",
      fields: [
        { id: 'strategy', coreValues: false, levels: ["עדות מינימלית לאסטרטגיית משימה", "עדות חלקית לאסטרטגיית משימה", "עדות ניכרת לאסטרטגיית משימה"] },
        { id: 'resources', coreValues: true, levels: ["שימוש מינימלי במשאבי בנייה ותכנות", "שימוש מוגבל במשאבי בנייה ותכנות", "שימוש ניכר במשאבי בנייה ותכנות לתמיכה באסטרטגיית המשימה"] },
      ] },
    { id: 'design', title: "תכנון",
      description: "הקבוצה עבדה ביחד על תכנון הרובוט ופיתחה את המיומנויות הנדרשות של בנייה ותכנות.",
      fields: [
        { id: 'contribution', coreValues: true, levels: ["עדות מינימלית שכל חברי הקבוצה תרמו רעיונות", "עדות חלקית שכל חברי הקבוצה תרמו רעיונות", "עדות ניכרת שכל חברי הקבוצה תרמו רעיונות"] },
        { id: 'skills', coreValues: false, levels: ["עדות מינימלית למיומנויות בנייה ותכנות אצל כל חברי הקבוצה", "עדות חלקית למיומנויות בנייה ותכנות אצל כל חברי הקבוצה", "עדות ניכרת למיומנויות בנייה ותכנות אצל כל חברי הקבוצה"] },
      ] },
    { id: 'create', title: "יצירה",
      description: "הקבוצה פיתחה תכנונים הנדסיים מקוריים או שיפרה תכנונים קיימים בהתאם לאסטרטגיית המשימה שלה.",
      fields: [
        { id: 'attachments', coreValues: false, levels: ["הסבר לא ברור של התוספות והייעוד שלהן", "הסבר פשטני של התוספות והייעוד שלהן", "הסבר מפורט של התוספות החדשניות והייעוד שלהן"] },
        { id: 'code', coreValues: false, levels: ["הסבר לא ברור של התוכנה ו/או שימוש בחיישנים", "הסבר פשטני של התוכנה ו/או שימוש בחיישנים", "הסבר מפורט של התוכנה ו/או שימוש חדשני בחיישנים"] },
      ] },
    { id: 'iterate', title: "חזרה ושינוי",
      description: "הקבוצה ביצעה בדיקות חוזרות של הרובוט והתוכנה במטרה לזהות תחומים שדורשים שיפור ושילבה את הממצאים בפתרונות שלה.",
      fields: [
        { id: 'test', coreValues: false, levels: ["עדות מינימלית לבדיקות הרובוט והתוכנה", "עדות חלקית לבדיקות הרובוט והתוכנה", "עדות ניכרת לבדיקות חוזרות של הרובוט והתוכנה"] },
        { id: 'improve', coreValues: true, levels: ["עדות מינימלית לשיפורים שהוכנסו בעקבות הבדיקות", "עדות חלקית לשיפורים שהוכנסו בעקבות הבדיקות", "עדות ניכרת לשיפורים שהוכנסו בעקבות הבדיקות"] },
      ] },
    { id: 'communicate', title: "הצגה",
      description: "הקבוצה הסבירה באופן תכליתי מה היא למדה מתהליך תכנון הרובוט וחגגה את התקדמותה.",
      fields: [
        { id: 'explanation', coreValues: true, levels: ["הסבר לא ברור של התהליך והפקת לקחים", "הסבר פשטני של התהליך והפקת לקחים", "הסבר מפורט של התהליך והפקת לקחים"] },
        { id: 'pride', coreValues: true, levels: ["הקבוצה מדגימה גאווה או התלהבות מינימלית מהעבודה שלה", "הקבוצה מדגימה גאווה או התלהבות חלקית מהעבודה שלה", "הקבוצה מדגימה גאווה או התלהבות ניכרת מהעבודה שלה"] },
      ] },
  ] },
};

const RUBRIC_LEVELS = ['מתחילה', 'מתפתחת', 'מיומנת', 'מצטיינת'];
// Column colors per tab, as on the official site.
const RUBRIC_COLORS = {
  innovation: ['#E9ECF7', '#BDC6E4', '#90A3D2', '#5E82BF'],
  robot:      ['#EDF4EC', '#C6DDC5', '#99C69C', '#64AF75'],
  values:     ['#FAECEA', '#F3D0C9', '#EBB3AA', '#E4928B'],
};
