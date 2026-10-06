# ใบงานปฏิบัติสัปดาห์ที่ 8: Local Database & Persistence ด้วย Drift

**วิชา** การพัฒนาซอฟต์แวร์สำหรับอุปกรณ์เคลื่อนที่ | **เครื่องมือ** Flutter, Drift, sqlite3_flutter_libs, build_runner, Google AI Studio

> 🔗 **ความต่อเนื่องของโปรเจกต์:** ใบงานนี้สืบทอดโดยตรงจากโปรเจกต์ **`campus_marketplace_w7`** ที่ทำไว้จนจบใบงานการทดลองที่ 7 ตอนนี้โปรเจกต์มี: หน้า **Home** ที่ดึงสินค้าจริงจาก Fake Store API (สัปดาห์ 6), ตะกร้าสินค้า (`CartModel`, สัปดาห์ 5), หน้า **"ลงประกาศขายสินค้า" (Sell)** ที่ใช้ Gemini Vision ช่วยแนะนำ title/category/description จากรูปภาพ (สัปดาห์ 7) และโครง **Bottom Navigation Bar** (`MainScaffold`) ที่มี 2 Tab แรกคือ "หน้าหลัก" กับ "ลงประกาศขาย"  **ยังไม่มี** ฟีเจอร์ "ถูกใจ" (Favorites) และร่างประกาศที่ AI ช่วยแนะนำ หลังกดยืนยันจะถูกเก็บไว้ใน State ชั่วคราวของ `SellItemPage` เท่านั้น **หายไปทันทีที่ปิดแอป**
>
> สัปดาห์นี้คือจุดที่ฟีเจอร์ **"รายการโปรด" (Favorites) ถูกสร้างขึ้น** พร้อมกันกับการนำร่างประกาศมาบันทึกถาวร ทั้งสองฟีเจอร์จะเข้าถึงข้อมูลผ่าน **Repository Pattern** เช่นเดียวกับที่ `ItemRepository`/`ItemRepositoryApi` ทำกับ REST API ในสัปดาห์ที่ 6 **ทำต่อในโฟลเดอร์ `campus_marketplace_w7` เดิม ห้ามสร้างโปรเจกต์ใหม่แยกต่างหาก** 

---

## วัตถุประสงค์การเรียนรู้

เมื่อทำใบงานนี้เสร็จสิ้น ผู้เรียนจะสามารถ

1. ใช้ AI ช่วยร่างโครงสร้างตาราง (Schema) จากคำอธิบายฟีเจอร์เป็นภาษาธรรมชาติ แล้วประเมิน/ปรับแก้ด้วยตนเอง
2. ติดตั้งและตั้งค่า Drift พร้อมรัน Code Generation ด้วย `build_runner` ได้ถูกต้อง
3. ประกาศตาราง (`Table`) และคลาสฐานข้อมูล (`AppDatabase`) ตามหลักการที่เรียนในบทหนังสือเรียนหัวข้อ 8.4
4. ออกแบบและเขียน Repository Pattern (Interface + Implementation) สำหรับ Local Database เองได้ โดยไม่ต้องมีตัวอย่างสำเร็จรูปครบทุกเมธอด
5. สร้างฟีเจอร์ "ถูกใจ" (Favorites) และนำร่างประกาศขายสินค้าจากสัปดาห์ที่ 7 มาบันทึกถาวรด้วย Drift ได้จริง
6. เพิ่ม Tab ใหม่เข้า Bottom Navigation Bar (`MainScaffold`) ที่มีอยู่แล้วได้ โดยไม่กระทบโค้ดของ Tab เดิม
7. ทดสอบและยืนยันว่าแอปทำงานแบบ Offline-first ได้จริง คือข้อมูลไม่หายแม้ปิดแอปหรือปิดอินเทอร์เน็ต

## สิ่งที่ต้องเตรียมก่อนเริ่ม

- โปรเจกต์ `campus_marketplace_w7` จากใบงานการทดลองที่ 7 ที่รันได้ปกติครบทุก Checkpoint แล้ว (มีหน้า Home, Checkout, Sell พร้อม `MainScaffold` 2 Tab)
- บัญชี Google AI Studio ที่ใช้มาตั้งแต่สัปดาห์ที่ 1
- ติดตั้ง Flutter SDK เวอร์ชันล่าสุดที่รองรับ Null Safety เต็มรูปแบบ (ตรวจสอบด้วย `flutter --version`)

⚠️ **ข้อควรระวัง**: การเปลี่ยนโครงสร้างตาราง (เพิ่ม/ลบ/แก้ไขคอลัมน์) หลังรัน `build_runner` ไปแล้วครั้งหนึ่ง ต้องรันคำสั่งเดิมซ้ำทุกครั้ง มิเช่นนั้นไฟล์ `.g.dart` จะไม่ตรงกับโค้ดล่าสุดและโปรเจกต์จะไม่คอมไพล์ผ่าน หากเจอปัญหานี้ให้ดูหัวข้อ Troubleshooting ท้ายใบงาน

---

## ส่วนที่ 1: ใช้ AI ช่วยร่าง Schema ก่อนเขียนโค้ด

ตามหลักการในบทหนังสือเรียนหัวข้อ 8.3 การออกแบบ Schema ต้องทำก่อนเขียนโค้ดเสมอ สัปดาห์นี้จะฝึกใช้ Gemini ช่วยร่าง Schema เบื้องต้น แล้วนำมาตรวจสอบและปรับแก้ด้วยตนเอง เพราะ AI ช่วยคิดได้เร็ว แต่การตัดสินใจสุดท้ายต้องเป็นของนักพัฒนาเสมอ (หลักการเดียวกับที่เรียนเรื่อง Responsible AI ในสัปดาห์ที่ 7)

### ขั้นตอนที่ 1.1 🔧 ทำตามขั้นตอน

เปิด Google AI Studio (https://aistudio.google.com) แล้วส่ง Prompt นี้ให้ Gemini

```
ฉันกำลังพัฒนาแอป Flutter ชื่อ Campus Marketplace ด้วย Drift (ORM สำหรับ SQLite)
ต้องการออกแบบตารางสองตาราง

1. เก็บรายการสินค้าที่ผู้ใช้กดถูกใจเป็นครั้งแรก 
   ต้องรู้ว่าถูกใจสินค้าชิ้นไหน (อ้างอิงจาก id สินค้าที่เป็นตัวเลข)
   เก็บชื่อ ราคา รูปภาพไว้ด้วยเพื่อแสดงผลได้โดยไม่ต้องเรียก API ซ้ำ และต้องเรียงตามเวลาที่กดถูกใจล่าสุดได้

2. เก็บร่างประกาศขายสินค้าที่ AI ช่วยแนะนำจากรูปภาพ (ปัจจุบันเก็บไว้ใน State ชั่วคราวเท่านั้น หายเมื่อปิดแอป)
   มีชื่อประกาศ หมวดหมู่ คำบรรยาย และ path ของรูปภาพในเครื่อง ต้องรู้ว่าแก้ไขล่าสุดเมื่อไหร่

ช่วยร่างโค้ด Dart ของ Class ที่ extends Table ทั้งสองตาราง พร้อมระบุชนิดข้อมูล (Column type)
ของแต่ละคอลัมน์ และเหตุผลว่าทำไมเลือกชนิดข้อมูลนั้น
```

บันทึกโค้ดที่ Gemini ตอบกลับมาที่ด้านล่าง

โค้ด Dart สำหรับทั้ง 2 ตาราง (extends Table)

```text

import 'package:drift/drift.dart';

// ===============================================================
// ตารางที่ 1: FavoriteProducts (เก็บรายการสินค้าที่ถูกใจ)
// ===============================================================
@TableIndex(name: 'idx_favorites_liked_at', columns: {#likedAt})
class FavoriteProducts extends Table {
  /// รหัสสินค้าอ้างอิงจากระบบ Backend/API
  IntColumn get productId => integer()();

  /// ชื่อสินค้า (จำกัดความยาวเพื่อความปลอดภัยและประหยัดพื้นที่)
  TextColumn get name => text().withLength(min: 1, max: 250)();

  /// ราคาสินค้า รองรับทศนิยม เช่น 250.00
  RealColumn get price => real()();

  /// URL รูปภาพสินค้าบนคลาวด์/CDN สำหรับใช้กับ Network Image Cache
  TextColumn get imageUrl => text().nullable()();

  /// วันและเวลาที่กดถูกใจล่าสุด (ตั้งค่าเริ่มต้นเป็นเวลาปัจจุบันขณะบันทึก)
  DateTimeColumn get likedAt => dateTime().withDefault(currentDateAndTime)();

  /// ใช้ productId เป็น Primary Key ป้องกันการกดถูกใจซ้ำซ้อน
  @override
  Set<Column> get primaryKey => {productId};
}

// ===============================================================
// ตารางที่ 2: ListingDrafts (เก็บบันทึกร่างประกาศขายสินค้าจาก AI)
// ===============================================================
@TableIndex(name: 'idx_drafts_updated_at', columns: {#updatedAt})
class ListingDrafts extends Table {
  /// รหัสร่างประกาศขายภายในเครื่อง เพิ่มขึ้นอัตโนมัติ (1, 2, 3...)
  IntColumn get id => integer().autoIncrement()();

  /// ชื่อประกาศที่ AI สกัดแนะนำมาให้ (nullable เผื่อกำลังร่าง)
  TextColumn get title => text().nullable()();

  /// หมวดหมู่สินค้า เช่น "หนังสือเรียน", "อุปกรณ์ไอที", "เสื้อผ้า"
  TextColumn get category => text().nullable()();

  /// คำบรรยายรายละเอียดสินค้าที่ AI ช่วยเขียนสรุปให้
  TextColumn get description => text().nullable()();

  /// Path ของไฟล์ภาพในเครื่องโทรศัพท์ เช่น /data/user/0/.../draft_img.jpg
  TextColumn get imageLocalPath => text()();

  /// ราคาตั้งต้นที่ AI แนะนำ (ออปชันเสริมเพื่อความสมบูรณ์แบบ)
  RealColumn get suggestedPrice => real().nullable()();

  /// วันเวลาที่มีการแก้ไขร่างล่าสุด
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// วันเวลาที่สร้างร่างขึ้นมาครั้งแรก
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

```

```text
ตัวอย่างการเขียน Query ใน Drift ตามโจทย์
1. ดึงรายการสินค้าที่ถูกใจ "เรียงตามเวลาล่าสุด":
code
Dart
Stream<List<FavoriteProduct>> watchRecentFavorites() {
  return (select(favoriteProducts)
        ..orderBy([(t) => OrderingTerm.desc(t.likedAt)]))
      .watch();
}
2. ดึงร่างสินค้า AI "เรียงตามเวลาแก้ไขล่าสุด":
code
Dart
Stream<List<ListingDraft>> watchDraftsByLatestUpdate() {
  return (select(listingDrafts)
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
      .watch();
}
3. อัปเดตเนื้อหาร่างสินค้าพร้อมแสตมป์เวลาแก้ไขล่าสุด:
code
Dart
Future<void> updateDraft({
  required int draftId,
  String? title,
  String? category,
  String? description,
}) {
  return (update(listingDrafts)..where((t) => t.id.equals(draftId))).write(
    ListingDraftsCompanion(
      title: Value(title),
      category: Value(category),
      description: Value(description),
      updatedAt: Value(DateTime.now()), // แสตมป์เวลาปัจจุบัน
    ),
  );
}
คำสั่งสร้าง Generated Code ในโปรเจกต์ Flutter
อย่าลืมรันคำสั่ง build runner หลังจากเพิ่มโค้ดตาราง:
code
Bash
dart run build_runner build --delete-conflicting-outputs

```

### ขั้นตอนที่ 1.2: ตรวจสอบและเทียบกับหลักการในบทเรียน 🧠 คิดเอง

เปรียบเทียบ Schema ที่ได้จาก Gemini กับหลักการในบทเรียนหัวข้อ 8.3 แล้วตอบคำถามต่อไปนี้ โดยการสรุปตามความเข้าใจของตนเอง (ห้ามคัดลอกคำตอบจาก Gemini มาวางตรง ๆ)

- Gemini กำหนด Primary Key ให้แต่ละตารางถูกต้องหรือไม่ (ควรเป็น Auto-increment Integer ตามที่อธิบายในบทเรียน)
- คอลัมน์ราคาสินค้า Gemini เลือกชนิดข้อมูลใด ตรงกับที่บทเรียนแนะนำ (`RealColumn`/`double`) หรือไม่ หากไม่ตรง ให้แก้ไขเอง
- Gemini เสนอให้เก็บสำเนาข้อมูล (เช่น ชื่อ/ราคาสินค้า) ซ้ำไว้ในตาราง Favorites หรือแนะนำให้เก็บแค่ `itemId` แล้วไปเรียก API ใหม่ทุกครั้ง หากแนะนำแบบหลัง ให้อธิบายตามหลักการ Offline-first ในบทหนังสือเรียนหัวข้อ 8.6 ว่าทำไมแนวทางนั้นไม่เหมาะกับสถานการณ์ที่ไม่มีอินเทอร์เน็ต
- Gemini กำหนดให้คอลัมน์ที่อ้างอิงสินค้า (`itemId`) ห้ามมีค่าซ้ำกัน (`.unique()`) หรือไม่ ถ้าไม่ได้กำหนด ให้เพิ่มเอง เพราะถ้าไม่มีข้อบังคับนี้ ผู้ใช้กดหัวใจสินค้าชิ้นเดียวกันซ้ำได้ไม่จำกัด ทำให้ตาราง Favorites มีแถวซ้ำกันสะสมไปเรื่อย ๆ

> ✅ **Checkpoint 1.1** บันทึกคำตอบจากคำถามด้านบนทั้ง 4 ข้อ พร้อมแนบภาพหน้าจอผลลัพธ์จาก Gemini

```text
1. Primary Key: ListingDrafts ถูกต้อง (autoIncrement) แต่ FavoriteProducts
   ใช้ productId จาก API เป็น PK ซึ่งไม่ตรงบทเรียน ควรมี id แบบ
   auto-increment เป็นของตัวเอง แล้วเก็บ id สินค้าในคอลัมน์ itemId แยก

2. ราคา: Gemini ใช้ RealColumn (double) ตรงกับบทเรียน ไม่ต้องแก้

3. สำเนาข้อมูล: Gemini เก็บสำเนา name/price/imageUrl ไว้ในตาราง
   เหมาะกับ Offline-first เพราะถ้าเก็บแค่ id ตอนไม่มีเน็ตจะเรียก
   API ไม่ได้ จึงไม่มีข้อมูลแสดงผล

4. unique(): Gemini ไม่ได้ใช้ .unique() แต่กันซ้ำด้วยการตั้ง productId
   เป็น PK แทน ผมแก้เป็น id auto-increment + itemId.unique()
   เพื่อให้ตรงบทเรียนและป้องกันแถวซ้ำสะสม
```

![alt text](image/image.png)


---

## ส่วนที่ 2: ติดตั้ง Drift และประกาศตาราง

### ขั้นตอนที่ 2.1: ติดตั้งแพ็กเกจ 🔧 ทำตามขั้นตอน

เพิ่ม dependency ในไฟล์ `pubspec.yaml` ของโปรเจกต์ `campus_marketplace_w7` **ต่อจาก** `http`, `provider` และ `image_picker` ที่มีอยู่แล้วจากสัปดาห์ที่ 6-7 (ไม่ต้องลบของเดิม)

```yaml
dependencies:
  drift: ^2.20.0
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.4
  path: ^1.9.0

dev_dependencies:
  drift_dev: ^2.20.0
  build_runner: ^2.4.13
```

รัน `flutter pub get` ในเทอร์มินัล

### ขั้นตอนที่ 2.2: สร้างไฟล์ประกาศตาราง 🔧 ทำตามขั้นตอน

สร้างไฟล์ `lib/database/tables.dart` ตามโครงสร้างในบทเรียนหัวข้อ 8.4 (ใช้ Schema ตามบทเรียน เพื่อให้ตรงกับใบงานการทดลองในส่วนถัดไป )

```dart
import 'package:drift/drift.dart';

class FavoriteItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId => integer().unique()(); // .unique() ป้องกันถูกใจสินค้าชิ้นเดียวกันซ้ำ
  TextColumn get title => text()();
  RealColumn get price => real()();
  TextColumn get imageUrl => text()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('ListingDraftRow') // ตั้งชื่อ Class ที่ Generate เอง ดูคำอธิบายด้านล่าง
class ListingDrafts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get category => text()();
  TextColumn get description => text()();
  TextColumn get imagePath => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

⚠️ **จุดที่พลาดง่ายมากในสัปดาห์นี้โดยเฉพาะ**: ปกติ Drift จะตั้งชื่อ Class ที่ Generate จากตารางด้วยการตัด `s` ท้ายชื่อ Table ออก (เช่นตาราง `FavoriteItems` → Class `FavoriteItem` ตามที่เรียนในบทหนังสือเรียน) ถ้าปล่อยให้ `ListingDrafts` ทำแบบเดียวกัน Drift จะสร้าง Class ชื่อ `ListingDraft` ออกมา ซึ่ง**ชนกับ Class `ListingDraft` ที่สร้างไว้แล้วตั้งแต่ใบงานการทดลองที่ 7** (เก็บแค่ `title`/`category`/`description` ที่ได้จาก AI ก่อนบันทึก) ทำให้โปรเจกต์มี 2 Class ชื่อเดียวกันคนละความหมายและคอมไพล์ไม่ผ่านเพราะ import ชนกัน Annotation `@DataClassName('ListingDraftRow')` ด้านบนแก้ปัญหานี้โดยสั่งให้ Driftตั้งชื่อ Class ที่ Generate เป็น `ListingDraftRow` แทน 


---

## ส่วนที่ 3: สร้างคลาสฐานข้อมูลหลักและรัน Code Generation

### ขั้นตอนที่ 3.1: สร้าง AppDatabase 🔧 ทำตามขั้นตอน

ดูตัวอย่างโค้ดเต็มในบทเรียนหัวข้อ 8.4 ขั้นตอนที่ 3 แล้วคัดลอกมาสร้างไฟล์ `lib/database/app_database.dart` ของตนเอง (import ตารางจาก `tables.dart` ที่สร้างในส่วนที่ 2 เข้ามาใช้งาน พร้อม `@DriftDatabase(tables: [FavoriteItems, ListingDrafts])`) หากตั้งชื่อ Class ของตารางต่างจากตัวอย่าง ให้แก้ชื่อใน `@DriftDatabase(tables: [...])` ให้ตรงกับชื่อจริงใน `tables.dart` ของตนเองด้วย


### ขั้นตอนที่ 3.2: รัน Code Generation 🔧 ทำตามขั้นตอน

รันคำสั่งต่อไปนี้ในเทอร์มินัลของ VS Code ที่โฟลเดอร์โปรเจกต์

```bash
dart run build_runner build --delete-conflicting-outputs
```

รอจนกระบวนการเสร็จสิ้น ตรวจสอบว่ามีไฟล์ `lib/database/app_database.g.dart` ถูกสร้างขึ้นใหม่ และตรวจสอบใน Debug Console ว่าไม่มี Error เรื่อง Class ชื่อซ้ำ (ถ้าเจอ ให้กลับไปตรวจสอบ ขั้นตอน 2.2 ว่าใส่ `@DataClassName` ไว้ถูกต้องหรือไม่)

### ขั้นตอนที่ 3.3: เชื่อม AppDatabase เข้ากับแอป 🧠 คิดเอง (มีโครงให้)
**นักศึกษาเขียน Code เอง**

สัปดาห์นี้ซับซ้อนกว่าเดิมเล็กน้อย เพราะ `main.dart` ต้องสร้าง `AppDatabase` ขึ้นมาหนึ่งอินสแตนซ์ แล้วส่งต่อให้ Repository **สองตัว** (Favorites และ Draft) ที่จะสร้างในส่วนที่ 4-5 ก่อนส่งเข้า `MainScaffold` อีกที ตรวจสอบตามโครงนี้แล้วเติมส่วนที่ยังไม่มี (Repository ทั้งสองตัวจะสร้างจริงในส่วนถัดไป ตอนนี้แค่เตรียมจุดเชื่อมไว้ก่อน)

```
ในฟังก์ชัน main():
    สร้าง AppDatabase() ขึ้นมา 1 ตัว เก็บไว้ในตัวแปร db

    เรียก runApp() ห่อด้วย ChangeNotifierProvider<CartModel> เหมือนเดิม
    ส่ง db เข้าไปเป็นพารามิเตอร์ของ MyApp (เพิ่ม field ใหม่ใน MyApp รับค่า AppDatabase)

ใน MyApp.build(context):
    สร้าง MainScaffold โดยส่งพารามิเตอร์ 3 ตัวเข้าไป:
        itemRepository: ItemRepositoryApi() (ตัวเดิมจากสัปดาห์ที่ 6-7)
        favoritesRepository: สร้างจาก AppDatabase ที่รับมา (จะเขียน Class จริงในส่วนที่ 4)
        draftRepository: สร้างจาก AppDatabase ตัวเดียวกัน (จะเขียน Class จริงในส่วนที่ 5)
```

> 💡 สังเกตว่า `AppDatabase` ถูกสร้างขึ้น **ครั้งเดียว** ใน `main()` แล้วส่งต่อผ่าน Constructor ไปเรื่อย ๆ (Dependency Injection) หลักการเดียวกับที่ `ItemRepositoryApi()` ถูกสร้างครั้งเดียวแล้วส่งต่อมาตั้งแต่สัปดาห์ที่ 6 — ห้ามสร้าง `AppDatabase()` ใหม่หลายจุดในแอปเดียวกัน เพราะแต่ละอินสแตนซ์จะเปิดการเชื่อมต่อไฟล์ฐานข้อมูลแยกจากกัน ทำให้ข้อมูลที่เขียนจากจุดหนึ่งอาจไม่ปรากฏอีกจุดหนึ่ง

> ✅ **Checkpoint 3.1**

capture หน้าจอผลลัพธ์คำสั่ง `dart run build_runner build` จากขั้นตอนที่ 3.2 ที่แสดงว่าสร้างไฟล์สำเร็จ (ไม่มี Error เรื่อง Class ชื่อซ้ำ) จากนั้นเปิดไฟล์ main.dart ที่แก้ตามขั้นตอนที่ 3.3 โดย ยังไม่ต้องรันแอปในจุดนี้ เพราะ VS Code จะขีดเส้นสีแดงใต้ FavoritesRepositoryDrift และ ListingDraftRepositoryDrift (ยังไม่มี Class จริง จะเขียน Class นี้ในส่วนที่ 4-5) และถ้าสั่งรันตอนนี้แอปจะ Error ทันทีเพราะคอมไพล์ไม่ผ่าน ถือเป็นเรื่องปกติ — จะกลับมารันแอปได้จริงอีกครั้งหลังทำ Checkpoint 4.1 และ 5.1 เสร็จ

- หน้าจอผลลัพธ์คำสั่ง `dart run build_runner build` จากขั้นตอนที่ 3.2
![alt text](image/image-1.png)

- เปิดไฟล์ main.dart ที่แก้ตามขั้นตอนที่ 3.3 
![alt text](image/image-2.png)

---

## ส่วนที่ 4: สร้างฟีเจอร์ "รายการโปรด" (Favorites) ตั้งแต่ต้น

นี่คือฟีเจอร์ใหม่ทั้งหมดของแอป ประกอบด้วย 4 ส่วนที่ต้องทำให้ครบ คือ 1.Repository 2.ปุ่มกดถูกใจในหน้า Home 3.หน้าจอแสดงรายการโปรด และ 4.การเพิ่ม Tab ที่ 3 เข้า Bottom Navigation Bar

### ขั้นตอนที่ 4.1: สร้าง Repository Interface และ Implementation 
**นักศึกษาเขียน Code เอง**

สร้างไฟล์ `lib/repositories/favorites_repository.dart` (Interface) และ `lib/repositories/favorites_repository_drift.dart` (Implementation) เองทั้งหมด โดยอ้างอิงโครงสร้างและลำดับขั้นตอนจากบทเรียนหัวข้อ 8.4 (ซึ่งสอนตัวอย่างนี้ไว้แบบเต็มทุกบรรทัดอยู่แล้ว) สังเกตว่ารูปแบบนี้เหมือนกับ `ItemRepository`/`ItemRepositoryApi` ในสัปดาห์ที่ 6 ทุกประการ เพียงแค่เปลี่ยนจากการเรียก REST API มาเป็นการเรียก Drift แทน


**ข้อกำหนดที่ต้องมีครบ (ตรวจสอบตัวเองก่อนไปต่อ):**

- Interface `FavoritesRepository` ต้องมีอย่างน้อย 3 เมธอด: `addFavorite(int itemId, String title, double price, String imageUrl)`, `getAllFavorites()` (คืนค่า `Future<List<FavoriteItem>>` เรียงจากกดถูกใจล่าสุด), `removeFavorite(int itemId)`
- Class `FavoritesRepositoryDrift implements FavoritesRepository` ต้องรับ `AppDatabase` เข้ามาทาง Constructor (เหมือน `final AppDatabase _db;`)
- ทุกเมธอดต้องเขียนลง/อ่านจาก `_db.favoriteItems` เท่านั้น ห้ามมีโค้ดเรียก `http`/Dio ปะปนอยู่เลย (ตามหลักการ Offline-first หัวข้อ 8.6)
- `getAllFavorites()` ต้องเรียงผลลัพธ์ด้วย `orderBy` ตามคอลัมน์ `addedAt` จากใหม่ไปเก่า
- `addFavorite(...)` ต้องเรียก `.insert(...)` พร้อมระบุ `mode: InsertMode.insertOrIgnore` เพราะคอลัมน์ `itemId` เป็น `.unique()` (Checkpoint 2.1) ถ้าไม่ใส่ การกดหัวใจซ้ำที่สินค้าชิ้นเดิมจะทำให้แอป Error ด้วย `UNIQUE constraint failed` แทนที่จะแค่ไม่มีอะไรเกิดขึ้น

### ขั้นตอนที่ 4.2: เพิ่มปุ่ม "กดถูกใจ" ในหน้า Home 🧠 คิดเอง (มีโครงให้)

แก้ไข `lib/screens/home_page.dart` ให้รับ `FavoritesRepository` เข้ามาทาง Constructor เพิ่มอีก 1 ตัว (คู่กับ `ItemRepository` ที่มีอยู่แล้ว) แล้วเพิ่มไอคอนรูปหัวใจต่อท้ายแต่ละแถวสินค้าใน `ListTile` คู่กับไอคอนตะกร้าที่มีอยู่แล้ว

**แนวทางเขียนโค้ด (Pseudocode)** — ลองไล่ตามลำดับนี้แล้วแปลงเป็น Dart ด้วยตัวเอง

```
ใน HomePage (StatefulWidget):
    เพิ่ม field favoritesRepository ชนิด FavoritesRepository ใน Constructor

ใน trailing ของแต่ละ ListTile (ปัจจุบันมีแค่ปุ่มตะกร้า):
    เปลี่ยนจาก IconButton เดี่ยว เป็น Row ที่มี mainAxisSize: MainAxisSize.min แล้วใส่ 2 ปุ่ม:
        ปุ่มที่ 1: ไอคอนรูปหัวใจ (Icons.favorite_border)
            เมื่อกด → เรียก widget.favoritesRepository.addFavorite(item.id, item.title, item.price, item.imageUrl)
            เนื่องจากเป็น Future ต้องจัดการ error ด้วย try/catch หรือ .catchError() แล้วแสดง SnackBar แจ้งผล (สำเร็จ/ผิดพลาด)
        ปุ่มที่ 2: ปุ่มตะกร้าเดิม (ไม่ต้องแก้ไข)
```

**คำใบ้ / จุดที่ต้องระวัง**

- `addFavorite(...)` เป็น `Future<void>` ดังนั้นฟังก์ชันที่เรียกมันใน `onPressed` ควรเป็น `async` เพื่อ `await` และจับ error ได้ถูกต้อง
- ไม่ต้องเปลี่ยนไอคอนหัวใจให้ทึบ (Toggle สถานะ) ในสัปดาห์นี้ — แค่กดแล้วเพิ่มลงฐานข้อมูลสำเร็จพร้อม SnackBar ยืนยันก็เพียงพอ (การเอาออกจากรายการโปรดทำที่หน้า Favorites โดยเฉพาะในขั้นตอนถัดไป เหมือนกับที่การลบออกจากตะกร้าทำที่หน้า Checkout ไม่ใช่หน้า Home)
- อย่าลืมแก้จุดที่สร้าง `HomePage(...)` ใน `MainScaffold` (ขั้นตอนที่ 4.4) ให้ส่ง `favoritesRepository` เข้าไปด้วย ไม่งั้นจะ Error ว่าพารามิเตอร์ที่จำเป็นหายไป

### ขั้นตอนที่ 4.3: สร้างหน้าจอ "รายการโปรด" (FavoritesPage) 
**นักศึกษาเขียน Code เอง**
สร้างไฟล์ `lib/screens/favorites_page.dart` เป็น `StatefulWidget` ที่รับ `FavoritesRepository` เข้ามาทาง Constructor

**ข้อกำหนดที่ต้องมีครบ:**

- ใช้ `FutureBuilder` เรียก `repository.getAllFavorites()` ใน `initState()` (รูปแบบเดียวกับ `HomePage` ที่เรียก `repository.getItems()` มาตั้งแต่สัปดาห์ที่ 6)
- จัดการ 3 สถานะให้ครบ: กำลังโหลด (`CircularProgressIndicator`), รายการว่างเปล่า (ข้อความแนะนำ เช่น "ยังไม่มีรายการโปรด ลองกดหัวใจที่หน้าหลักดูสิ"), และมีข้อมูล (`ListView.builder` แสดง title/price/imageUrl)
- แต่ละแถวมีปุ่มลบ (`IconButton` ไอคอนถังขยะ) ที่เรียก `repository.removeFavorite(itemId)` แล้ว `setState()` เพื่อโหลดรายการใหม่ (เรียก `getAllFavorites()` ซ้ำแล้วอัปเดต Future ที่ผูกกับ `FutureBuilder`)
- ไม่ต้องรับ `ItemRepository` เข้ามาในหน้านี้ เพราะข้อมูลที่แสดง (title/price/imageUrl) ถูกเก็บสำเนาไว้ในตาราง `FavoriteItems` ครบอยู่แล้วตามที่ออกแบบไว้ในส่วนที่ 1 — ไม่ต้องเรียก Fake Store API ซ้ำ

### ขั้นตอนที่ 4.4: เพิ่ม Tab ที่ 3 เข้า MainScaffold ที่มีอยู่แล้ว 🔧 ทำตามขั้นตอน

ตามที่ `campus_marketplace_lab_roadmap.md` หัวข้อ 2.1 วางแผนไว้ Favorites คือ Tab ที่ 3 ของแอป เปิดไฟล์ `lib/screens/main_scaffold.dart` ที่สร้างไว้แล้วตั้งแต่สัปดาห์ที่ 7 แล้วแก้ไขตามนี้ **ไม่ต้องแก้ไขโค้ดภายใน `HomePage` หรือ `SellItemPage` เพิ่มเติมจากที่ทำในขั้นตอนก่อนหน้านี้**

```dart
// ก่อนแก้
class MainScaffold extends StatefulWidget {
  final ItemRepository repository;
  const MainScaffold({super.key, required this.repository});
  // ...
}
```

```dart
// หลังแก้
class MainScaffold extends StatefulWidget {
  final ItemRepository itemRepository;
  final FavoritesRepository favoritesRepository;
  final ListingDraftRepository draftRepository; // จะมีจริงหลังทำส่วนที่ 5 เสร็จ
  const MainScaffold({
    super.key,
    required this.itemRepository,
    required this.favoritesRepository,
    required this.draftRepository,
  });
  // ...
}
```

และในเมธอด `build`

```dart
// ก่อนแก้
final pages = [
  HomePage(repository: widget.repository),
  const SellItemPage(),
];
// ...
items: const [
  BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'หน้าหลัก'),
  BottomNavigationBarItem(icon: Icon(Icons.add_a_photo), label: 'ลงประกาศขาย'),
],
```

```dart
// หลังแก้
final pages = [
  HomePage(
    repository: widget.itemRepository,
    favoritesRepository: widget.favoritesRepository,
  ),
  SellItemPage(draftRepository: widget.draftRepository),
  FavoritesPage(repository: widget.favoritesRepository),
];
// ...
items: const [
  BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'หน้าหลัก'),
  BottomNavigationBarItem(icon: Icon(Icons.add_a_photo), label: 'ลงประกาศขาย'),
  BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'รายการโปรด'),
],
```

อย่าลืมเพิ่ม `import 'favorites_page.dart';`, `import '../repositories/favorites_repository.dart';` และ `import '../repositories/listing_draft_repository.dart';` ที่หัวไฟล์ และแก้ `lib/main.dart` ให้ส่งพารามิเตอร์ตามชื่อใหม่ (`itemRepository:`, `favoritesRepository:`, `draftRepository:`) ตามโครงที่วางไว้ในขั้นตอนที่ 3.3

> ⚠️ `IndexedStack` อ้างอิง index ตามตำแหน่งใน List `pages` และ `BottomNavigationBarItem` ต้องมีจำนวนเท่ากับ `pages` เสมอ (ตอนนี้ต้องเป็น 3 ทั้งคู่) ถ้าจำนวนไม่ตรงกันแอปจะ Error ทันทีตอนรัน ไม่ใช่แค่แสดงผลผิด

> ✅ **Checkpoint 4.1** รันแอปแล้วทดสอบ: (ก) กดหัวใจที่สินค้า 3 ชิ้นจากหน้า Home (ข) สลับไป Tab "รายการโปรด" เห็นครบทั้ง 3 ชิ้น (ค) ปิดแอปให้สนิท (Force Stop หรือปัดออกจาก Recent Apps) แล้วเปิดใหม่ กลับไปที่ Tab รายการโปรดอีกครั้ง ถ่ายภาพหน้าจอ (ข) และ (ค) เทียบกัน ต้องแสดงรายการเดิมครบทุกชิ้น พร้อมทดสอบกดลบ (Remove) 1 ชิ้น แล้วปิดเปิดแอปใหม่อีกครั้งเพื่อยืนยันว่าการลบก็ถูกบันทึกถาวรเช่นกัน (ง) กลับไปหน้า Home แล้วกดหัวใจซ้ำที่สินค้าชิ้นเดิมอีกครั้ง (ชิ้นที่ยังไม่ได้ลบ) แล้วตรวจสอบที่ Tab รายการโปรดว่ายังแสดงสินค้าชิ้นนั้นแค่แถวเดียว ไม่ซ้ำเป็น 2 แถว และแอปไม่ Error

(ก) กดหัวใจที่สินค้า 3 ชิ้นจากหน้า Home 
![alt text](image/image-3.png)
![alt text](image/image-4.png)

(ข) สลับไป Tab "รายการโปรด" เห็นครบทั้ง 3 ชิ้น
![alt text](image/image-5.png)

(ค) ปิดแอปให้สนิท (Force Stop หรือปัดออกจาก Recent Apps) แล้วเปิดใหม่ กลับไปที่ Tab รายการโปรดอีกครั้ง
![alt text](image/image-6.png)
![alt text](image/image-7.png)
![alt text](image/image-8.png)

(ง) กลับไปหน้า Home แล้วกดหัวใจซ้ำที่สินค้าชิ้นเดิมอีกครั้ง (ชิ้นที่ยังไม่ได้ลบ) แล้วตรวจสอบที่ Tab รายการโปรดว่ายังแสดงสินค้าชิ้นนั้นแค่แถวเดียว ไม่ซ้ำเป็น 2 แถว และแอปไม่ Error
![alt text](image/image-9.png)
![alt text](image/image-10.png)

---

## ส่วนที่ 5: นำร่างประกาศขายสินค้า (สัปดาห์ที่ 7) มาบันทึกถาวร

### ขั้นตอนที่ 5.1: สร้าง Repository สำหรับ Draft 
**นักศึกษาเขียน Code เอง**

สร้างไฟล์ `lib/repositories/listing_draft_repository.dart` (Interface) และ `lib/repositories/listing_draft_repository_drift.dart` (Implementation) ในรูปแบบเดียวกับส่วนที่ 4 ทุกประการ แต่ทำงานกับตาราง `ListingDrafts` แทน

**ข้อกำหนดที่ต้องมีครบ:**

- Interface `ListingDraftRepository` ต้องมีอย่างน้อย 3 เมธอด: `saveDraft(ListingDraft draft, String imagePath)` (บันทึกร่างใหม่ — รับ `ListingDraft` ที่มีอยู่แล้วจากสัปดาห์ 7 บวก path รูปภาพแยกต่างหาก เพราะ `ListingDraft` เดิมไม่มี field นี้), `getAllDrafts()` (คืนค่า `Future<List<ListingDraftRow>>` เรียงจากแก้ไขล่าสุด — สังเกตว่าใช้ `ListingDraftRow` ไม่ใช่ `ListingDraft` ตามที่อธิบายไว้ใน Checkpoint 2.1), และ `deleteDraft(int id)`
- `saveDraft(...)` ต้องดึงค่า `draft.title`, `draft.category`, `draft.description` มาประกอบกับ `imagePath` ที่รับมาแยก แล้วสร้าง `ListingDraftsCompanion.insert(...)` ก่อน `.insert()` ลงฐานข้อมูล

### ขั้นตอนที่ 5.2: แก้ไขหน้า "ลงประกาศขายสินค้า" ให้บันทึกร่างถาวร 🔧 ทำตามขั้นตอน 

เปิดไฟล์ `sell_item_page.dart` จากสัปดาห์ที่ 7 แก้ไข 2 จุด: (1) รับ `ListingDraftRepository` เข้ามาทาง Constructor และ (2) แก้ปุ่ม "ยืนยันร่างประกาศ" (ที่เดิมแค่เก็บค่าไว้ใน State ชั่วคราวตามใบงานสัปดาห์ที่ 7 ส่วนที่ 5.2)

```dart
// ก่อนแก้
class SellItemPage extends StatefulWidget {
  const SellItemPage({super.key});
  // ...
}
```

```dart
// หลังแก้
class SellItemPage extends StatefulWidget {
  final ListingDraftRepository draftRepository;
  const SellItemPage({super.key, required this.draftRepository});
  // ...
}
```

และในปุ่ม "ยืนยันร่างประกาศ" เปลี่ยนจากการเก็บค่าไว้ในตัวแปร State เฉย ๆ ให้เรียก `await widget.draftRepository.saveDraft(draft, imageFile!.path)` แทน จัดการ Loading/Success/Error ระหว่างบันทึกเช่นเดียวกับที่เคยทำตอนเรียก Gemini Vision ในสัปดาห์ที่ 7 แล้วค่อยแสดง `SnackBar` ยืนยันและล้างฟอร์มเหมือนเดิมหลังบันทึกสำเร็จ

### ขั้นตอนที่ 5.3: สร้างหน้าจอ "ร่างประกาศของฉัน" (My Drafts) 
**นักศึกษาเขียน Code เอง**

สร้างหน้าจอใหม่ `lib/screens/my_drafts_page.dart` ที่รับ `ListingDraftRepository` เข้ามาทางConstructor เรียก `repository.getAllDrafts()` แสดงรายการร่างทั้งหมดที่เคยบันทึกไว้เป็น `ListView` (รูปแบบเดียวกับ `FavoritesPage` ในส่วนที่ 4.3) แต่ละรายการแสดงชื่อประกาศ หมวดหมู่ และวันเวลาที่แก้ไขล่าสุด พร้อมปุ่มลบร่างที่ไม่ต้องการแล้ว จัดการสถานะ Loading/Success/Empty ให้ครบ

**ทำไมหน้านี้ไม่ใช่ Tab ที่ 4**: ตาม `campus_marketplace_lab_roadmap.md` หัวข้อ 2.1 มีกฎชัดเจนว่าอะไรควรเป็น Tab (ปลายทางหลักที่สลับไปมาตลอดเวลา) กับอะไรควรเป็น Push/Pop (Flow เฉพาะกิจที่มีจุดเริ่ม-จบ) "ร่างประกาศของฉัน" เป็นหน้าจัดการร่างที่ผูกกับ Flow การลงประกาศโดยตรง ไม่ใช่ปลายทางหลักที่ผู้ใช้เปิดดูตลอดเวลาเหมือน Favorites อีกทั้ง Roadmap ได้กำหนดไว้แล้วว่า Tab ที่ 4 ของแอปคือ "โปรไฟล์" ในสัปดาห์หน้า การเพิ่ม Tab ใหม่อีกตัวตอนนี้จะทำให้ลำดับ Tab ทั้งเทอมเพี้ยนไปจากแผน **จึงให้เข้าถึงหน้านี้ด้วยปุ่มไอคอนใน AppBar ของ Tab "ลงประกาศขาย" แทน** (เช่น `IconButton(icon: Icon(Icons.history), onPressed: () => Navigator.push(...))`) เพิ่ม `AppBar` ให้ `SellItemPage` ถ้ายังไม่มี แล้วใส่ปุ่มนี้ไว้ที่ `actions`

> ✅ **Checkpoint 5.1** รันแอปแล้วทำตามลำดับนี้: 1. สร้างร่างประกาศใหม่ผ่าน Tab "ลงประกาศขาย" ด้วยความช่วยเหลือของ AI เหมือนสัปดาห์ที่ 7 2. กดยืนยันร่าง 3. กดปุ่มไอคอนเข้าหน้า "ร่างประกาศของฉัน" แล้วเห็นร่างที่เพิ่งสร้าง 4. ปิดแอปให้สนิทแล้วเปิดใหม่ กลับเข้าหน้า "ร่างประกาศของฉัน" อีกครั้ง ถ่ายภาพหน้าจอทั้ง 4 ขั้นตอนนี้แนบส่ง เพื่อพิสูจน์ว่าร่างไม่หายไปแม้ปิดแอปแล้ว 

 1. สร้างร่างประกาศใหม่ผ่าน Tab "ลงประกาศขาย" ด้วยความช่วยเหลือของ AI เหมือนสัปดาห์ที่ 7
 ![alt text](image/image-11.png)

 2. กดยืนยันร่าง
![alt text](image/image-12.png)

3. กดปุ่มไอคอนเข้าหน้า "ร่างประกาศของฉัน" แล้วเห็นร่างที่เพิ่งสร้าง
![alt text](image/image-13.png)

4. ปิดแอปให้สนิทแล้วเปิดใหม่ กลับเข้าหน้า "ร่างประกาศของฉัน" อีกครั้ง 
![alt text](image/image-14.png)
![alt text](image/image-15.png)
---

## ส่วนที่ 6: ทดสอบสถานการณ์ Offline-first

### ขั้นตอนที่ 6.1: ปิดอินเทอร์เน็ตแล้วทดสอบ 🔧 ทำตามขั้นตอน

ปิด Wi-Fi และ Data บนอุปกรณ์ทดสอบ แล้วเปิดแอป `campus_marketplace_w7` เข้าไปที่ Tab "รายการโปรด" และหน้า "ร่างประกาศของฉัน"

> ✅ **Checkpoint 6.1** ถ่ายภาพหน้าจอที่แสดงให้เห็นว่า Tab รายการโปรดและหน้าร่างประกาศยังคงแสดงข้อมูลได้ตามปกติแม้ไม่มีอินเทอร์เน็ตเลย (ส่วน Tab หน้าหลักที่ดึงจาก Fake Store API คาดว่าจะแสดง Error ตามปกติ เพราะยังไม่ได้ทำ Local Cache ให้หน้านั้น) 

![alt text](image/image-16.png)
![alt text](image/image-17.png)
![alt text](image/image-19.png)
![alt text](image/image-18.png)
---

## ปัญหาที่พบบ่อยและวิธีแก้ไข (Troubleshooting)

**Error พูดถึง Class `ListingDraft` ชนกัน หรือ `The name 'ListingDraft' is defined in multiple libraries`** เกิดจากลืมใส่ `@DataClassName('ListingDraftRow')` บนตาราง `ListingDrafts` ใน `tables.dart` ตามที่เตือนไว้ใน Checkpoint 2.1 ทำให้ Drift สร้าง Class ชื่อ `ListingDraft` ซ้ำกับ Class เดิมจากสัปดาห์ที่ 7 ให้เพิ่ม Annotation นี้แล้วรัน `dart run build_runner build --delete-conflicting-outputs` ใหม่อีกครั้ง

**Error: `Target of URI hasn't been generated: 'app_database.g.dart'`** เกิดจากยังไม่ได้รันคำสั่ง `dart run build_runner build --delete-conflicting-outputs` หรือรันแล้วแต่มีข้อผิดพลาดระหว่างสร้างโค้ดที่ยังไม่ได้แก้ไข ให้ตรวจสอบผลลัพธ์ในเทอร์มินัลตอนรันคำสั่งนี้ให้ละเอียด มักมีข้อความบอกบรรทัดที่ผิดพลาดในไฟล์ `tables.dart`

**รัน `build_runner` แล้วค้างนานผิดปกติหรือ error ว่า `Conflicting outputs`** ให้ลองรันคำสั่ง `dart run build_runner clean` ก่อน แล้วค่อยรัน `dart run build_runner build --delete-conflicting-outputs` ใหม่อีกครั้ง

**`The named parameter 'favoritesRepository'/'draftRepository' isn't defined` ตอนแก้ `main_scaffold.dart`/`home_page.dart`/`sell_item_page.dart`** เกิดจากแก้ Constructor ของไฟล์หนึ่งแล้ว แต่ยังไม่ได้แก้จุดที่เรียกใช้ Widget นั้นให้ส่งพารามิเตอร์ใหม่ครบ ให้ไล่ตรวจทั้ง 3 ไฟล์ตามลำดับ: `main.dart` → `main_scaffold.dart` → `home_page.dart`/`sell_item_page.dart` ว่าชื่อพารามิเตอร์ตรงกันทุกจุด

**แอป Error ทันทีตอนเปิด บอกประมาณ `RangeError` หรือ Bottom Navigation Bar กับหน้าจอไม่ตรงกัน** เกิดจากจำนวนรายการใน List `pages` ของ `MainScaffold` ไม่เท่ากับจำนวน `BottomNavigationBarItem` (ต้องเป็น 3 รายการทั้งคู่หลังทำ Checkpoint 4.1) ให้ตรวจนับทั้งสองรายการให้ตรงกัน

**แอป Crash ด้วยข้อความเกี่ยวกับ `sqlite3` ตอนรันบน Android จริง** ตรวจสอบว่าเพิ่ม `sqlite3_flutter_libs` ใน `pubspec.yaml` ครบถ้วนแล้ว และรัน `flutter clean` ตามด้วย `flutter pub get` ใหม่อีกครั้งก่อนรันแอป

**ข้อมูลหายไปหลังแก้ไขโครงสร้างตาราง (เพิ่ม/ลบคอลัมน์)** เกิดจากไม่ได้เพิ่มค่า `schemaVersion` และเขียนโค้ด Migration รองรับ ตามที่เตือนไว้ในบทหนังสือเรียนหัวข้อ 8.4 ระหว่างพัฒนา (ยังไม่ปล่อยให้ผู้ใช้จริงใช้งาน) วิธีแก้ชั่วคราวที่ง่ายที่สุดคือถอนการติดตั้งแอปออกจากอุปกรณ์ทดสอบแล้วติดตั้งใหม่ เพื่อล้างไฟล์ฐานข้อมูลเก่าทิ้ง (ห้ามใช้วิธีนี้กับแอปที่ผู้ใช้จริงติดตั้งอยู่แล้ว)

**หน้า Favorites/My Drafts แสดงค้างที่ Loading ตลอด ไม่ขึ้นข้อมูล** มักเกิดจากลืมเรียก `setState()` หลังจากได้ผลลัพธ์จาก `await repository.getAllFavorites()`/`getAllDrafts()` กลับมา (โดยเฉพาะหลังกดลบแล้วต้องการให้ List รีเฟรช) ตรวจสอบตามรูปแบบเดียวกับที่แก้ปัญหานี้มาแล้วในสัปดาห์ที่ 6

**กดหัวใจที่หน้า Home แล้วไม่มีอะไรเกิดขึ้นเลย ไม่มี Error ด้วย** มักเกิดจากลืม `await` หน้า `addFavorite(...)` หรือลืมเขียนโค้ดแสดง `SnackBar` หลังเรียกสำเร็จ ให้ตรวจสอบว่าฟังก์ชันใน `onPressed` ประกาศเป็น `async` และมี `await` ก่อนเรียก `ScaffoldMessenger.of(context).showSnackBar(...)`

**กดหัวใจซ้ำที่สินค้าชิ้นเดิมแล้วแอป Error ด้วยข้อความเกี่ยวกับ `UNIQUE constraint failed`** เกิดจากลืมใส่ `mode: InsertMode.insertOrIgnore` ตอนเรียก `_db.into(_db.favoriteItems).insert(...)` ใน `addFavorite()` เพราะคอลัมน์ `itemId` ถูกกำหนดเป็น `.unique()` ไว้ใน `tables.dart` (Checkpoint 2.1) ทำให้ Insert ซ้ำ `itemId` เดิมไม่ได้ ให้เพิ่มพารามิเตอร์ `mode: InsertMode.insertOrIgnore` เข้าไปในคำสั่ง `.insert(...)`
