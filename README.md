# Dark Matter - Complete Website

هذه النسخة مجهزة من الصفر وتحتوي على:
- صور الرئيسية بمقطع انتقالي Fade/Zoom.
- صور الإدارة.
- 43 سيارة داخل المتجر.
- سعر ثابت لكل سيارة: 22.99 ريال.
- تسجيل دخول Discord عبر Supabase Auth.
- الملف الشخصي + طلبات المشتري.
- نظام مشرفين الموقع: صاحب الموقع يضيف الإيميلات.
- لوحة الطلبات للمشرفين مع التاريخ، الاستلام، وتحديث الحالة.
- نموذج دفع Moyasar (mada / Visa / Mastercard).
- التحقق من نجاح الدفع على Backend عبر Supabase Edge Function.

## الأشياء الوحيدة التي لا أستطيع تعبئتها بدلاً عنك
هذه أسرار/مفاتيح حسابك ولم ترسلها، لذلك وضعت أماكن واضحة لها:

### 1) assets/js/config.js
ضع:
- SUPABASE_URL
- SUPABASE_ANON_KEY
- MOYASAR_PUBLISHABLE_KEY (يبدأ pk_)
- وتأكد أن SITE_URL هو رابط GitHub Pages الفعلي.

### 2) supabase/setup.sql
تم وضع بريد صاحب الموقع بالفعل:
alarmierahmed@gmail.com
شغّل الملف كامل في Supabase SQL Editor.

### 3) Supabase Authentication > Providers > Discord
فعّل Discord وأدخل Client ID و Client Secret من Discord Developer Portal.
استخدم Callback URL الذي يعرضه لك Supabase داخل Discord OAuth2 Redirects.
وفي Supabase URL Configuration أضف رابط GitHub Pages في Site URL و Redirect URLs.

### 4) Moyasar
في config.js ضع Publishable Key فقط (pk_test_ أو pk_live_).

للتأكد من الدفع الحقيقي، انشر Edge Function:
supabase/functions/verify-moyasar/index.ts

ثم أضف Secret باسم:
MOYASAR_SECRET_KEY
وقيمته Secret Key من ميسّر (sk_...)

لا تضع Secret Key داخل index.html أو config.js.

## رفع GitHub
إذا ستحذف محتويات المستودع، ارفع محتويات هذا المجلد إلى جذر المستودع، بحيث يكون index.html مباشرة في الجذر:
index.html
assets/
supabase/
README.md

ثم GitHub > Settings > Pages:
Deploy from a branch
main
/(root)


## صلاحيات الإدارة
- صاحب الموقع: alarmierahmed@gmail.com
- زر "مشرفين الموقع" يظهر لصاحب الموقع فقط.
- زر "الطلبات" يظهر لصاحب الموقع وللمشرفين الذين يضيفهم صاحب الموقع فقط.
- العميل العادي لا يرى "مشرفين الموقع" ولا لوحة جميع الطلبات.
- المشتري يرى طلباته الخاصة فقط من الملف الشخصي.
- الحماية ليست مجرد إخفاء أزرار؛ قواعد Supabase RLS تمنع غير المصرح لهم من قراءة جميع الطلبات أو إدارة المشرفين.
