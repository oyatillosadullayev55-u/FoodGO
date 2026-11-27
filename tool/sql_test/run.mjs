// SQL migratsiyalarini lokal (xotiradagi) Postgres'da sinaydi.
// Haqiqiy Supabase bazasiga ulanmaydi.
//   cd tool/sql_test && npm install && npm test
import { PGlite } from '@electric-sql/pglite';
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';

const sql = (name) =>
  readFileSync(new URL(`../../supabase/${name}`, import.meta.url), 'utf8');

const db = new PGlite();
await db.exec(readFileSync(new URL('./stubs.sql', import.meta.url), 'utf8'));

const ids = {
  admin: '10000000-0000-4000-8000-000000000001',
  customer: '10000000-0000-4000-8000-000000000002',
  owner: '10000000-0000-4000-8000-000000000003',
  courier: '10000000-0000-4000-8000-000000000004',
  master: '10000000-0000-4000-8000-000000000005',
  other: '10000000-0000-4000-8000-000000000006',
};
const emails = {
  admin: 'admin@foodgo.uz',
  customer: 'customer@example.com',
  owner: 'owner.foodgo@example.com',
  courier: 'courier.foodgo@example.com',
  master: 'master@example.com',
  other: 'other@example.com',
};
for (const k of Object.keys(ids)) {
  await db.query('insert into auth.users (id, email) values ($1, $2)', [ids[k], emails[k]]);
}

const SHOP = 'b1000000-0000-4000-8000-000000000001';
const AIRPODS = 'a1000000-0000-4000-8000-000000000001';
const ALI = 'e1000000-0000-4000-8000-000000000001';

let passed = 0;
async function test(name, fn) {
  try {
    await fn();
    passed++;
    console.log(`  ok  ${name}`);
  } catch (e) {
    console.error(`FAIL  ${name}\n      ${e.message}`);
    process.exitCode = 1;
  } finally {
    await db.exec('reset role');
    await login(null);
  }
}

async function login(who) {
  const sub = who ? ids[who] : '';
  const claims = who ? JSON.stringify({ sub, email: emails[who] }) : '';
  await db.query("select set_config('request.jwt.claim.sub', $1, false)", [sub]);
  await db.query("select set_config('request.jwt.claims', $1, false)", [claims]);
}
async function as(who) {
  await db.exec('reset role');
  await login(who);
  await db.exec(`set role ${who ? 'authenticated' : 'anon'}`);
}
const rows = async (q, p) => (await db.query(q, p)).rows;
const one = async (q, p) => (await rows(q, p))[0];
const fails = (q, p, pattern) => assert.rejects(db.query(q, p), pattern);
/** RLS tufayli 0 qator o'zgarishi kerak. */
const untouched = async (q, p) => assert.equal((await db.query(q, p)).affectedRows, 0);

await test('barcha skriptlar tartib bilan va qayta ishga tushadi', async () => {
  await db.exec(sql('seed_demo.sql'));
  await db.exec(sql('roles_setup.sql'));
  for (let i = 0; i < 2; i++) {
    await db.exec(sql('super_app.sql'));
    await db.exec(sql('seed_super_demo.sql'));
  }
});

// Test uchun rollar
await db.exec(`
  update public.profiles set role = 'shop' where id = '${ids.owner}';
  update public.profiles set role = 'master' where id = '${ids.master}';
  update public.profiles set full_name = 'Azizbek', phone = '+998901234567' where id = '${ids.courier}';
  update public.restaurants set owner_id = '${ids.owner}', owner_email = '${emails.owner}' where id = '${SHOP}';
  update public.masters set user_id = '${ids.master}' where id = '${ALI}';
`);

await test('eski restoranlar tasdiqlangan, yangisi kutilmoqda', async () => {
  const r = await one("select count(*)::int n from public.restaurants where verification_status <> 'approved'");
  assert.equal(r.n, 0);
  const n = await one("insert into public.restaurants (name) values ('Yangi') returning verification_status v");
  assert.equal(n.v, 'pending');
});

await test('mehmon faqat tasdiqlangan do\'kon, usta va servislarni ko\'radi', async () => {
  await db.exec("update public.masters set verification_status = 'pending' where full_name = 'Bekzod Usta'");
  await as(null);
  assert.equal((await rows("select 1 from public.restaurants where name = 'Yangi'")).length, 0);
  assert.equal((await rows('select 1 from public.masters')).length, 2);
  assert.equal((await rows('select 1 from public.services')).length, 6);
  assert.equal((await rows('select 1 from public.transactions')).length, 0);
});

await test('begona foydalanuvchi do\'konni o\'zgartira olmaydi', async () => {
  for (const script of ['super_app.sql', 'roles_setup.sql', 'super_app.sql']) {
    await db.exec('reset role');
    await db.exec(sql(script));
    await as(null);
    await untouched("update public.restaurants set name = 'buzildi' where owner_email is null");
    await as('customer');
    await untouched("update public.restaurants set name = 'buzildi'");
  }
});

await test('hamkor o\'zini tasdiqlay olmaydi va komissiyani o\'zgartira olmaydi', async () => {
  await db.exec(`update public.restaurants set verification_status = 'pending', is_active = false where id = '${SHOP}'`);
  await as('owner');
  await db.query(
    "update public.restaurants set verification_status = 'approved', commission_percent = 0, rating = 5, kind = 'restaurant', is_active = true where id = $1",
    [SHOP],
  );
  const r = await one('select * from public.restaurants where id = $1', [SHOP]);
  assert.equal(r.verification_status, 'pending');
  assert.equal(r.commission_percent, null);
  assert.equal(r.kind, 'shop');
  assert.equal(r.is_active, true);
  await as('admin');
  await db.query("update public.restaurants set verification_status = 'approved' where id = $1", [SHOP]);
  assert.equal((await one('select verification_status v from public.restaurants where id = $1', [SHOP])).v, 'approved');
});

async function placeOrder(qty) {
  await as('customer');
  const r = await one('select public.test_create_order($1, $2, $3) id', [SHOP, AIRPODS, qty]);
  return r.id;
}
const stock = async () => {
  await db.exec('reset role');
  return (await one('select stock from public.products where id = $1', [AIRPODS])).stock;
};

await test('buyurtma ombordan ayiradi, bekor qilinsa qaytaradi', async () => {
  const before = await stock();
  const id = await placeOrder(2);
  assert.equal(await stock(), before - 2);
  await as('customer');
  await db.query("select public.set_order_status($1, 'cancelled')", [id]);
  assert.equal(await stock(), before);
});

await test('omborda yetmasa buyurtma yaratilmaydi', async () => {
  await as('customer');
  await fails('select public.test_create_order($1, $2, 500)', [SHOP, AIRPODS], /Omborda yetarli emas/);
  await db.exec('reset role');
});

let delivered;
await test('magazin → kuryer → yetkazildi: komissiya, moliya va xabar', async () => {
  delivered = await placeOrder(1);
  await as('owner');
  for (const s of ['accepted', 'preparing', 'ready_for_pickup']) {
    await db.query('select public.set_order_status($1, $2)', [delivered, s]);
  }
  await as('courier');
  await db.query('select public.claim_order($1)', [delivered]);
  await db.query(
    'insert into public.courier_locations (courier_id, lat, lng) values ($1, 40.38, 71.78) on conflict (courier_id) do update set lat = excluded.lat',
    [ids.courier],
  );
  await as('customer');
  const live = await one('select * from public.get_order_courier($1)', [delivered]);
  assert.equal(live.full_name, 'Azizbek');
  assert.equal(live.lat, 40.38);
  await as('other');
  await fails('select * from public.get_order_courier($1)', [delivered], /Ruxsat/);
  await as('courier');
  for (const s of ['picked_up', 'on_the_way', 'delivered']) {
    await db.query('select public.set_order_status($1, $2)', [delivered, s]);
  }
  await as('customer');
  const after = await one('select * from public.get_order_courier($1)', [delivered]);
  assert.equal(after.lat, null, 'yetkazilgach joylashuv yashiriladi');
  assert.ok((await rows("select 1 from public.notifications where title = 'Buyurtmangiz yetkazildi'")).length);
  await as('owner');
  const t = await one('select * from public.transactions where order_id = $1', [delivered]);
  assert.equal(t.amount, Math.round(1990000 * 0.07));
});

await test('mijoz buyurtmani bir marta baholaydi, reyting yangilanadi', async () => {
  await as('customer');
  await db.query('select public.submit_review(3, $2, p_order_id => $1)', [delivered, 'Yaxshi']);
  await fails('select public.submit_review(5, null, p_order_id => $1)', [delivered], /allaqachon/);
  const r = await one('select rating::float r, rating_count c from public.restaurants where id = $1', [SHOP]);
  assert.deepEqual(r, { r: 3, c: 1 });
  await as('other');
  await fails('select public.submit_review(5, null, p_order_id => $1)', [delivered], /Faqat yetkazilgan/);
});

let request;
await test('xizmat buyurtmasi: yaratish va ruxsatlar', async () => {
  await as('customer');
  request = (await one(
    "select public.create_service_request($1, 'Santexnik', 'Farg''ona, Navoiy 5', '+998901112233') id",
    [ALI],
  )).id;
  await fails(
    "insert into public.service_requests (customer_id, master_id, phone, address_text, service_type, status, price) values ($1, $2, '1', 'x', 'x', 'completed', 1)",
    [ids.customer, ALI],
    /row-level security/,
  );
  await untouched("update public.service_requests set status = 'completed' where id = $1", [request]);
  await fails("select public.set_service_status($1, 'accepted')", [request], /o'tkazib bo'lmaydi/);
  await as('other');
  assert.equal((await rows('select 1 from public.service_requests')).length, 0);
  await fails("select public.set_service_status($1, 'cancelled')", [request], /Ruxsat/);
  await as(null);
  await fails("select public.set_service_status($1, 'cancelled')", [request], /permission denied/);
});

await test('usta ishni yakunlaydi: narx majburiy, komissiya hisoblanadi', async () => {
  await as('master');
  await db.query("select public.set_service_status($1, 'accepted')", [request]);
  await db.query("select public.set_service_status($1, 'in_progress')", [request]);
  await fails("select public.set_service_status($1, 'completed')", [request], /narxini/);
  await db.query("select public.set_service_status($1, 'completed', 200000)", [request]);
  const r = await one('select * from public.service_requests where id = $1', [request]);
  assert.equal(r.commission_amount, 24000);
  assert.equal((await rows('select 1 from public.transactions where service_request_id = $1', [request])).length, 1);
  await fails("select public.set_service_status($1, 'cancelled')", [request], /Yakunlangan/);
  await as('customer');
  await db.query('select public.submit_review(5, null, p_service_request_id => $1)', [request]);
  const m = await one('select rating::float r, rating_count c from public.masters where id = $1', [ALI]);
  assert.deepEqual(m, { r: 5, c: 1 });
  await as('master');
  await db.query('update public.masters set rating = 1, price_from = 90000 where id = $1', [ALI]);
  const m2 = await one('select rating::float r, price_from p from public.masters where id = $1', [ALI]);
  assert.deepEqual(m2, { r: 5, p: 90000 });
});

await test('mijoz o\'z rolini yoki blokini o\'zgartira olmaydi', async () => {
  await as('customer');
  await untouched("update public.profiles set role = 'admin', is_blocked = false where id = $1", [ids.customer]);
});

await test('bloklangan mijoz buyurtma bera olmaydi', async () => {
  await as('admin');
  await db.query('update public.profiles set is_blocked = true where id = $1', [ids.other]);
  await as('other');
  await fails('select public.test_create_order($1, $2, 1)', [SHOP, AIRPODS], /bloklangan/);
  await fails(
    "select public.create_service_request($1, 'x', 'Farg''ona, Navoiy 5', '+998901112233')",
    [ALI],
    /bloklangan/,
  );
});

await test('nizo: mijoz summa yoza olmaydi, admin qaytarishni tasdiqlaydi', async () => {
  await as('customer');
  await fails(
    "insert into public.complaints (order_id, subject, body, refund_amount) values ($1, 'a', 'b', 1000)",
    [delivered],
    /row-level security/,
  );
  await db.query("insert into public.complaints (order_id, subject, body) values ($1, 'Kechikdi', 'Juda kech keldi')", [delivered]);
  await as('other');
  await fails("insert into public.complaints (order_id, subject, body) values ($1, 'a', 'b')", [delivered], /row-level security/);
  await as('admin');
  await db.query("update public.complaints set status = 'resolved', resolution = 'Qaytarildi', refund_amount = 15000");
  const t = await one("select * from public.transactions where kind = 'refund'");
  assert.equal(t.amount, 15000);
});

await test('xabarnomalar auditoriya bo\'yicha ko\'rinadi', async () => {
  await as('admin');
  await db.exec("insert into public.notifications (title, body, audience) values ('Ustalarga', 'x', 'master'), ('Hammaga', 'x', 'all')");
  await as('customer');
  const titles = (await rows('select title from public.notifications where user_id is null')).map((r) => r.title);
  assert.deepEqual(titles, ['Hammaga']);
  await as('master');
  assert.equal((await rows('select 1 from public.notifications where user_id is null')).length, 2);
});

await test('analitika va firibgarlik faqat admin uchun', async () => {
  await as('customer');
  await fails('select public.admin_analytics()', [], /admin/);
  await fails('select * from public.fraud_signals()', [], /admin/);
  for (let i = 0; i < 5; i++) {
    const id = await placeOrder(1);
    await db.query("select public.set_order_status($1, 'cancelled')", [id]);
  }
  await as('admin');
  const signals = (await rows('select signal from public.fraud_signals()')).map((r) => r.signal);
  assert.ok(signals.includes('many_cancellations'), String(signals));
  assert.ok(signals.includes('order_burst'), String(signals));
  const a = (await one('select public.admin_analytics(7) a')).a;
  assert.equal(a.daily.length, 7);
  assert.equal(a.delivered, 1);
  assert.equal(a.commission, Math.round(1990000 * 0.07) + 24000);
  assert.equal(a.top_stores[0].name, 'TechnoMart');
});

await test('hujjat: faqat o\'z papkasiga yuklanadi', async () => {
  await as('master');
  await db.query("insert into storage.objects (bucket_id, name) values ('partner-docs', $1)", [`${ids.master}/pasport.jpg`]);
  await fails("insert into storage.objects (bucket_id, name) values ('partner-docs', $1)", [`${ids.other}/x.jpg`], /row-level security/);
  await db.query("insert into public.partner_documents (doc_type, file_path) values ('pasport', $1)", [`${ids.master}/pasport.jpg`]);
  await fails("insert into public.partner_documents (doc_type, file_path, status) values ('p', 'x', 'approved')", [], /row-level security/);
  await as('other');
  assert.equal((await rows('select 1 from storage.objects')).length, 0);
  assert.equal((await rows('select 1 from public.partner_documents')).length, 0);
});

console.log(`\n${passed} ta SQL testi o'tdi${process.exitCode ? ', xatolar bor' : ''}.`);
await db.close();
