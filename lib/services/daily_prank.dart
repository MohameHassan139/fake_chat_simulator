import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/language_helper.dart';

/// One line of a ready-made chat: [me] is the phone owner's side.
class PrankLine {
  final bool me;
  final String ar;
  final String en;
  const PrankLine(this.me, this.ar, this.en);
}

class PrankTemplate {
  final String titleAr;
  final String titleEn;
  final String contactAr;
  final String contactEn;
  final List<PrankLine> lines;
  const PrankTemplate(this.titleAr, this.titleEn, this.contactAr, this.contactEn, this.lines);
}

PrankLine _me(String ar, String en) => PrankLine(true, ar, en);
PrankLine _them(String ar, String en) => PrankLine(false, ar, en);

/// "Prank of the day": a new ready-made chat every day (one tap, then edit and
/// share), and one optional daily reminder. Everything is inside the app: no
/// server.
class DailyPrank {
  static final DailyPrank instance = DailyPrank._();
  DailyPrank._();

  static String text(bool isArabic, String ar, String en) => LanguageHelper.pick(isArabic, ar, en);

  /// Today's template: the same for everyone on the same day.
  PrankTemplate get today {
    final day = DateTime.now().difference(DateTime(2026, 1, 1)).inDays;
    return templates[day % templates.length];
  }

  // ─── The daily reminder ─────────────────────────────────────────────────

  static const String _askedKey = 'daily_prank_asked';
  static const String _onKey = 'daily_prank_reminder';
  static const int _id = 7001;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  Future<bool> reminderOn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onKey) ?? false;
  }

  /// Asked once, the first time the user takes today's prank.
  Future<void> offerReminderOnce(bool isArabic) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_askedKey) ?? false) return;
    await prefs.setBool(_askedKey, true);
    await setReminder(true, isArabic);
  }

  Future<void> setReminder(bool on, bool isArabic) async {
    if (kIsWeb) return;
    try {
      await _init();
      final prefs = await SharedPreferences.getInstance();
      if (!on) {
        await _plugin.cancel(id: _id);
        await prefs.setBool(_onKey, false);
        return;
      }
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final allowed = await android?.requestNotificationsPermission() ??
          await ios?.requestPermissions(alert: true, sound: true) ??
          false;
      if (!allowed) return;
      await _plugin.periodicallyShow(
        id: _id,
        repeatInterval: RepeatInterval.daily,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: text(isArabic, 'مقلب اليوم جاهز 😂', 'Today\'s prank is ready 😂'),
        body: text(isArabic, 'افتح وجرّبه على أصحابك', 'Open it and try it on your friends'),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_prank',
            'Prank of the day',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
      await prefs.setBool(_onKey, true);
    } catch (e) {
      debugPrint('DailyPrank reminder: $e');
    }
  }

  // ─── The templates ──────────────────────────────────────────────────────

  static final List<PrankTemplate> templates = [
    PrankTemplate('المدير غاضب', 'The angry boss', 'المدير', 'Boss', [
      _them('تعال مكتبي حالاً', 'Come to my office right now'),
      _me('خير يا فندم؟', 'Is everything okay, sir?'),
      _them('لا. ومعاك الشاحن بتاعي اللي أخدته من شهر', 'No. And bring the charger you borrowed a month ago'),
    ]),
    PrankTemplate('نتيجة الامتحان', 'Exam results', 'الأستاذ', 'Teacher', [
      _them('النتيجة طلعت', 'The results are out'),
      _me('وأنا جبت كام؟؟', 'What did I get??'),
      _them('أنت الأول على الفصل… من تحت', 'You are first in class… from the bottom'),
    ]),
    PrankTemplate('أمي اكتشفت', 'Mom found out', 'ماما', 'Mom', [
      _them('أنا عرفت كل حاجة', 'I know everything'),
      _me('عرفتي إيه بالظبط؟ 😳', 'Know what exactly? 😳'),
      _them('إنك أكلت الحلويات اللي كانت للضيوف', 'That you ate the sweets for the guests'),
    ]),
    PrankTemplate('فزت بجائزة', 'You won a prize', 'المسابقة', 'Contest', [
      _them('مبروك! فزت معنا بجائزة كبيرة 🎉', 'Congrats! You won a big prize 🎉'),
      _me('بجد؟ إيه هي؟', 'Really? What is it?'),
      _them('كيلو طماطم… توصيل مجاني', 'A kilo of tomatoes… free delivery'),
    ]),
    PrankTemplate('الجار والمفتاح', 'The neighbour and the key', 'الجار', 'Neighbour', [
      _them('لقيت مفتاحك على الباب من الصبح', 'Found your key in the door this morning'),
      _me('يا نهار! شكراً جداً', 'Oh no! Thanks a lot'),
      _them('العفو. التلاجة بتاعتك حلوة على فكرة', 'You\'re welcome. Nice fridge by the way'),
    ]),
    PrankTemplate('الكابتن', 'The coach', 'الكابتن', 'Coach', [
      _them('اختارناك في المنتخب', 'You were picked for the national team'),
      _me('مش ممكن!! 😍', 'No way!! 😍'),
      _them('منتخب الشطرنج للمبتدئين، تحت 8 سنين', 'The beginners chess team, under 8'),
    ]),
    PrankTemplate('الطيار', 'The pilot', 'كابتن الطيارة', 'Captain', [
      _them('الطيارة مستنياك أنت بس', 'The plane is waiting only for you'),
      _me('أنا جاي جري!!', 'I\'m running!!'),
      _them('خد وقتك، نسينا العجل كمان', 'Take your time, we forgot the wheels too'),
    ]),
    PrankTemplate('حبيبتك القديمة', 'The ex', 'رقم غير معروف', 'Unknown number', [
      _them('فاكرني؟', 'Remember me?'),
      _me('مين حضرتك؟', 'Who is this?'),
      _them('أنا البيتزا اللي طلبتها امبارح ولسه ماستلمتنيش 🍕', 'I\'m the pizza you ordered yesterday and never picked up 🍕'),
    ]),
    PrankTemplate('الدكتور', 'The doctor', 'الدكتور', 'Doctor', [
      _them('التحاليل وصلت', 'Your test results are here'),
      _me('خير يا دكتور؟', 'Is it bad, doctor?'),
      _them('عندك حالة نادرة: كسل مزمن يوم الجمعة', 'A rare case: chronic laziness on Fridays'),
    ]),
    PrankTemplate('صاحبك عنده سر', 'Your friend\'s secret', 'صاحبي', 'Best friend', [
      _them('لازم أقولك سر', 'I have to tell you a secret'),
      _me('قول بسرعة', 'Tell me quick'),
      _them('أنا اللي باكل الأكل بتاعك من التلاجة من 3 سنين', 'I\'ve been eating your food from the fridge for 3 years'),
    ]),
    PrankTemplate('خدمة العملاء', 'Customer service', 'خدمة العملاء', 'Support', [
      _them('تم تحويل رصيدك بنجاح', 'Your balance was transferred successfully'),
      _me('رصيد إيه؟ أنا ما حولتش حاجة!', 'What balance? I sent nothing!'),
      _them('ولا إحنا. بنتأكد بس إنك صاحي ☕', 'Neither did we. Just checking you\'re awake ☕'),
    ]),
    PrankTemplate('القطة', 'The cat', 'القطة', 'The cat', [
      _them('مياو', 'Meow'),
      _me('أنتي بتعرفي تكتبي؟!', 'You can type?!'),
      _them('أيوه. والأكل اتأخر ساعتين، هنتكلم بعدين', 'Yes. Dinner is two hours late, we will talk later'),
    ]),
    PrankTemplate('البطل الخارق', 'The superhero', 'الرجل الخارق', 'Superhero', [
      _them('محتاج مساعدتك في مهمة سرية', 'I need your help with a secret mission'),
      _me('أنا جاهز! إيه المهمة؟', 'I\'m ready! What is it?'),
      _them('تفتح لي برطمان المخلل، مش قادر', 'Open this pickle jar for me, I can\'t'),
    ]),
    PrankTemplate('الجيم', 'The gym', 'الجيم', 'Gym', [
      _them('اشتراكك خلص', 'Your membership has ended'),
      _me('بس أنا ما جيتش ولا مرة!', 'But I never came once!'),
      _them('عارفين، علشان كده بنشكرك على التبرع 💪', 'We know, thanks for the donation 💪'),
    ]),
    PrankTemplate('أبوك والإنترنت', 'Dad and the Wi-Fi', 'بابا', 'Dad', [
      _them('غيرت باسورد الواي فاي', 'I changed the Wi-Fi password'),
      _me('ليه؟ هو إيه الجديد؟', 'Why? What is it now?'),
      _them('اغسل الأطباق الأول وأقولك', 'Wash the dishes first and I\'ll tell you'),
    ]),
    PrankTemplate('المشهور', 'The celebrity', 'نجم مشهور ⭐', 'Famous star ⭐', [
      _them('شفت الفيديو بتاعك، تحفة!', 'Saw your video, amazing!'),
      _me('أنت بتهزر؟ 😱', 'Are you kidding? 😱'),
      _them('أيوه بهزر. أنا صاحبك غيرت اسمي 😂', 'Yes. It\'s your friend, I changed my name 😂'),
    ]),
    PrankTemplate('الطباخ', 'The chef', 'الشيف', 'Chef', [
      _them('الأكل اللي طبخته وصل للمسابقة', 'Your cooking made it to the contest'),
      _me('بجد؟ أي مسابقة؟', 'Really? Which contest?'),
      _them('أسوأ طعم في المدينة. مبروك 🏆', 'Worst taste in town. Congrats 🏆'),
    ]),
    PrankTemplate('المدرسة', 'School', 'المدرسة', 'School', [
      _them('بكرة امتحان مفاجئ', 'Surprise test tomorrow'),
      _me('في إيه؟؟', 'In what??'),
      _them('في كل حاجة', 'In everything'),
    ]),
    PrankTemplate('التاكسي', 'The taxi', 'السواق', 'Driver', [
      _them('أنا تحت البيت', 'I\'m downstairs'),
      _me('أنا ما طلبتش تاكسي!', 'I didn\'t order a taxi!'),
      _them('عارف. بس الأغنية اللي عندك عالية قوي 🎶', 'I know. Your music is just really loud 🎶'),
    ]),
    PrankTemplate('الكائن الفضائي', 'The alien', 'كوكب المريخ', 'Planet Mars', [
      _them('وصلنا الأرض', 'We have landed on Earth'),
      _me('أهلاً؟ 👽', 'Hello? 👽'),
      _them('فين أقرب محل شاورما؟', 'Where is the nearest shawarma place?'),
    ]),
    PrankTemplate('أختك', 'Your sister', 'أختي', 'Sister', [
      _them('ماما بتسأل مين كسر الكوباية', 'Mom is asking who broke the glass'),
      _me('أنا ما عملتش حاجة!', 'I didn\'t do anything!'),
      _them('اتأخرت، قلتلها إنه أنت 😇', 'Too late, I told her it was you 😇'),
    ]),
    PrankTemplate('البنك', 'The bank', 'البنك', 'The bank', [
      _them('رصيدك الحالي: 3 جنيه', 'Your current balance: 3 dollars'),
      _me('😭', '😭'),
      _them('نصيحة: بلاش الحلويات النهارده', 'Tip: skip dessert today'),
    ]),
    PrankTemplate('المهندس', 'The engineer', 'مهندس الصيانة', 'Repair guy', [
      _them('صلحنا الغسالة', 'We fixed the washing machine'),
      _me('ممتاز! كام الحساب؟', 'Great! How much?'),
      _them('الغسالة تمام. التلفزيون بقى هو اللي بيغسل', 'The washer is fine. Now the TV does the laundry'),
    ]),
    PrankTemplate('عيد الميلاد', 'The birthday', 'صاحبي', 'Friend', [
      _them('كل سنة وأنت طيب!! 🎂', 'Happy birthday!! 🎂'),
      _me('عيد ميلادي بعد 6 شهور', 'My birthday is in 6 months'),
      _them('أنا بحب أبقى أول واحد', 'I like being the first'),
    ]),
    PrankTemplate('الجدة', 'Grandma', 'تيتة', 'Grandma', [
      _them('اتعلمت أبعت رسايل!', 'I learned how to text!'),
      _me('برافو يا تيتة ❤️', 'Bravo grandma ❤️'),
      _them('ودلوقتي بتعلم أعمل لايك. استعد', 'Now I\'m learning to like posts. Get ready'),
    ]),
    PrankTemplate('الأكل اتأخر', 'Late delivery', 'الدليفري', 'Delivery', [
      _them('الأوردر في الطريق', 'Your order is on the way'),
      _me('من ساعتين وأنت بتقول كده!', 'You said that two hours ago!'),
      _them('الطريق طويل يا فندم 🛵', 'It\'s a long road, sir 🛵'),
    ]),
    PrankTemplate('الروبوت', 'The robot', 'الروبوت', 'Robot', [
      _them('تم تفعيل الذكاء الاصطناعي', 'Artificial intelligence activated'),
      _me('وهتعمل إيه؟', 'And what will you do?'),
      _them('هنام. ده أذكى قرار 😴', 'Sleep. Smartest decision 😴'),
    ]),
    PrankTemplate('الفرح', 'The wedding', 'ابن عمي', 'Cousin', [
      _them('أنت المسؤول عن الرقص في الفرح', 'You are in charge of dancing at the wedding'),
      _me('أنا ما بعرفش أرقص!', 'I can\'t dance!'),
      _them('ما هو ده المطلوب 😂', 'That\'s exactly the point 😂'),
    ]),
    PrankTemplate('الكورة', 'The match', 'صاحبي', 'Friend', [
      _them('فريقك كسب!!', 'Your team won!!'),
      _me('بجد؟؟ 🎉', 'Really?? 🎉'),
      _them('لا، بس كان نفسي أشوف فرحتك', 'No, I just wanted to see you happy'),
    ]),
    PrankTemplate('الأستاذ والواجب', 'Homework', 'الأستاذ', 'Teacher', [
      _them('فين الواجب؟', 'Where is your homework?'),
      _me('الكلب أكله', 'The dog ate it'),
      _them('أنت ما عندكش كلب', 'You don\'t have a dog'),
      _me('ما هو أكله ومشي', 'He ate it and left'),
    ]),
  ];
}
