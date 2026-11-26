/// Super Admin'ning jadvalga asoslangan modullari.
library;

import 'package:flutter/material.dart';

import '../../core/utils/money.dart';
import '../customer/home/service_tiles.dart';
import 'resource/admin_resource.dart';

const _categoryKinds = {'food': 'Taom', 'shop': 'Magazin', 'master': 'Usta'};
const _regionKinds = {
  'viloyat': 'Viloyat',
  'shahar': 'Shahar',
  'tuman': 'Tuman',
};
const _partnerAudiences = {
  'restaurant': 'Restoranlar',
  'shop': 'Magazinlar',
  'master': 'Ustalar',
  'courier': 'Kuryerlar',
};
const audiences = {
  'all': 'Hammaga',
  'customer': 'Mijozlar',
  ..._partnerAudiences,
};
const transactionKinds = {
  'commission': 'Komissiya',
  'payout': "Hamkorga to'lov",
  'refund': 'Qaytarish',
  'subscription': 'Obuna',
};
const _transactionStatuses = {
  'pending': 'Kutilmoqda',
  'done': 'Bajarildi',
  'cancelled': 'Bekor qilindi',
};
const _subscriptionStatuses = {
  'active': 'Faol',
  'expired': 'Muddati tugagan',
  'cancelled': 'Bekor qilingan',
};

const _serviceReference = Reference(
  'services',
  labelColumns: ['title'],
  valueColumn: 'code',
);
const _userReference = Reference(
  'profiles',
  labelColumns: ['full_name', 'email', 'phone'],
);

String _money(Object? v) => formatSom((v as num?) ?? 0);

final servicesResource = AdminResource(
  table: 'services',
  title: 'Servislar',
  createLabel: 'Yangi servis',
  icon: Icons.apps_rounded,
  orderBy: 'sort_order',
  ascending: true,
  itemTitle: (r) => r['title'] as String,
  itemSubtitle: (r) => '${r['code']} · ${r['route'] ?? 'sahifa yo\'q'}',
  fields: [
    const ResourceField(
      'code',
      'Kod',
      required: true,
      createOnly: true,
      hint: 'masalan: taxi',
    ),
    const ResourceField('title', 'Nomi', required: true),
    const ResourceField('subtitle', 'Qisqa izoh'),
    ResourceField(
      'icon',
      'Belgi',
      type: FieldType.choice,
      required: true,
      defaultValue: 'apps',
      options: {for (final k in serviceIcons.keys) k: k},
    ),
    const ResourceField(
      'route',
      "Ilovadagi yo'l",
      hint: "Bo'sh bo'lsa \"tez orada\" ko'rinadi",
    ),
    const ResourceField(
      'sort_order',
      'Tartib',
      type: FieldType.integer,
      required: true,
      defaultValue: 10,
    ),
    const ResourceField(
      'is_active',
      'Faol',
      type: FieldType.boolean,
      defaultValue: true,
    ),
  ],
);

final categoriesResource = AdminResource(
  table: 'categories',
  title: 'Kategoriyalar',
  createLabel: 'Yangi kategoriya',
  icon: Icons.category_rounded,
  orderBy: 'sort_order',
  ascending: true,
  itemTitle: (r) => '${r['icon'] ?? ''} ${r['name']}'.trim(),
  itemSubtitle: (r) =>
      '${_categoryKinds[r['kind']] ?? r['kind']}'
      '${r['parent_id'] == null ? '' : ' · subkategoriya'}',
  fields: const [
    ResourceField('name', 'Nomi', required: true),
    ResourceField(
      'kind',
      'Turi',
      type: FieldType.choice,
      required: true,
      defaultValue: 'food',
      options: _categoryKinds,
    ),
    ResourceField(
      'parent_id',
      'Yuqori kategoriya',
      type: FieldType.reference,
      reference: Reference('categories', labelColumns: ['name']),
    ),
    ResourceField('icon', 'Emoji'),
    ResourceField(
      'sort_order',
      'Tartib',
      type: FieldType.integer,
      required: true,
      defaultValue: 10,
    ),
  ],
);

final commissionResource = AdminResource(
  table: 'commission_rules',
  title: 'Komissiyalar',
  createLabel: 'Komissiya',
  icon: Icons.percent_rounded,
  orderBy: 'service_code',
  ascending: true,
  itemTitle: (r) => '${r['service_code']}: ${r['percent']}%',
  itemSubtitle: (r) => 'Hamkorga alohida foiz berilmagan bo\'lsa qo\'llanadi',
  fields: const [
    ResourceField(
      'service_code',
      'Servis',
      type: FieldType.reference,
      required: true,
      createOnly: true,
      reference: _serviceReference,
    ),
    ResourceField(
      'percent',
      'Foiz',
      type: FieldType.decimal,
      required: true,
      min: 0,
      max: 100,
    ),
  ],
);

final plansResource = AdminResource(
  table: 'subscription_plans',
  title: 'Tariflar',
  createLabel: 'Yangi tarif',
  icon: Icons.workspace_premium_rounded,
  orderBy: 'price',
  ascending: true,
  itemTitle: (r) => r['title'] as String,
  itemSubtitle: (r) =>
      '${_money(r['price'])} / ${r['period_days']} kun · '
      '${_partnerAudiences[r['audience']] ?? r['audience']}',
  fields: const [
    ResourceField('title', 'Nomi', required: true),
    ResourceField(
      'audience',
      'Kimlar uchun',
      type: FieldType.choice,
      required: true,
      options: _partnerAudiences,
    ),
    ResourceField(
      'price',
      "Narxi (so'm)",
      type: FieldType.integer,
      required: true,
      min: 0,
    ),
    ResourceField(
      'period_days',
      'Muddat (kun)',
      type: FieldType.integer,
      required: true,
      defaultValue: 30,
      min: 1,
    ),
    ResourceField('features', 'Imkoniyatlar', type: FieldType.multiline),
    ResourceField(
      'is_active',
      'Faol',
      type: FieldType.boolean,
      defaultValue: true,
    ),
  ],
);

final subscriptionsResource = AdminResource(
  table: 'subscriptions',
  title: 'Obunalar',
  createLabel: 'Obuna biriktirish',
  icon: Icons.card_membership_rounded,
  orderBy: 'ends_at',
  itemTitle: (r) => '${r['starts_at']} — ${r['ends_at']}',
  itemSubtitle: (r) =>
      '${_subscriptionStatuses[r['status']] ?? r['status']} · '
      'foydalanuvchi ${(r['user_id'] as String).substring(0, 8)}',
  fields: const [
    ResourceField(
      'plan_id',
      'Tarif',
      type: FieldType.reference,
      required: true,
      reference: Reference('subscription_plans', labelColumns: ['title']),
    ),
    ResourceField(
      'user_id',
      'Hamkor',
      type: FieldType.reference,
      required: true,
      reference: _userReference,
    ),
    ResourceField(
      'starts_at',
      'Boshlanishi',
      type: FieldType.date,
      required: true,
    ),
    ResourceField('ends_at', 'Tugashi', type: FieldType.date, required: true),
    ResourceField(
      'status',
      'Holat',
      type: FieldType.choice,
      required: true,
      defaultValue: 'active',
      options: _subscriptionStatuses,
    ),
  ],
);

final promotionsResource = AdminResource(
  table: 'promotions',
  title: 'Aksiyalar',
  createLabel: 'Yangi aksiya',
  icon: Icons.campaign_rounded,
  orderBy: 'sort_order',
  ascending: true,
  itemTitle: (r) => r['title'] as String,
  itemSubtitle: (r) =>
      '${r['starts_at']} — ${r['ends_at'] ?? 'muddatsiz'}'
      '${r['discount_percent'] == null ? '' : ' · -${r['discount_percent']}%'}',
  fields: const [
    ResourceField('title', 'Sarlavha', required: true),
    ResourceField('subtitle', 'Izoh'),
    ResourceField(
      'service_code',
      'Servis',
      type: FieldType.reference,
      reference: _serviceReference,
    ),
    ResourceField(
      'discount_percent',
      'Chegirma % (bannerda ko\'rsatiladi)',
      type: FieldType.integer,
      min: 0,
      max: 100,
    ),
    ResourceField('image_url', 'Rasm havolasi', hint: 'https://...'),
    ResourceField('starts_at', 'Boshlanishi', type: FieldType.date),
    ResourceField('ends_at', 'Tugashi', type: FieldType.date),
    ResourceField(
      'sort_order',
      'Tartib',
      type: FieldType.integer,
      required: true,
      defaultValue: 10,
    ),
    ResourceField(
      'is_active',
      'Faol',
      type: FieldType.boolean,
      defaultValue: true,
    ),
  ],
);

final notificationsResource = AdminResource(
  table: 'notifications',
  title: 'Xabarnomalar',
  createLabel: 'Xabar yuborish',
  icon: Icons.notifications_active_rounded,
  broadcastOnly: true,
  itemTitle: (r) => r['title'] as String,
  itemSubtitle: (r) =>
      '${audiences[r['audience']] ?? r['audience']} · ${r['body']}',
  fields: const [
    ResourceField(
      'audience',
      'Kimga',
      type: FieldType.choice,
      required: true,
      defaultValue: 'all',
      options: audiences,
    ),
    ResourceField('title', 'Sarlavha', required: true),
    ResourceField('body', 'Matn', type: FieldType.multiline, required: true),
  ],
);

final regionsResource = AdminResource(
  table: 'regions',
  title: 'Hududlar',
  createLabel: 'Yangi hudud',
  icon: Icons.map_rounded,
  orderBy: 'name',
  ascending: true,
  itemTitle: (r) => r['name'] as String,
  itemSubtitle: (r) => _regionKinds[r['kind']] ?? r['kind'] as String,
  fields: const [
    ResourceField('name', 'Nomi', required: true),
    ResourceField(
      'kind',
      'Turi',
      type: FieldType.choice,
      required: true,
      defaultValue: 'shahar',
      options: _regionKinds,
    ),
    ResourceField(
      'parent_id',
      'Qaysi viloyatda',
      type: FieldType.reference,
      reference: Reference('regions', labelColumns: ['name']),
    ),
    ResourceField(
      'sort_order',
      'Tartib',
      type: FieldType.integer,
      required: true,
      defaultValue: 10,
    ),
    ResourceField(
      'is_active',
      'Faol',
      type: FieldType.boolean,
      defaultValue: true,
    ),
  ],
);

/// Moliyaviy yozuvlar o'chirilmaydi, faqat holati o'zgaradi.
final transactionsResource = AdminResource(
  table: 'transactions',
  title: 'Moliya',
  createLabel: 'Yozuv qo\'shish',
  icon: Icons.account_balance_rounded,
  canDelete: false,
  itemTitle: (r) =>
      '${transactionKinds[r['kind']] ?? r['kind']}: ${_money(r['amount'])}',
  itemSubtitle: (r) =>
      '${_transactionStatuses[r['status']] ?? r['status']}'
      '${r['note'] == null ? '' : ' · ${r['note']}'}',
  fields: const [
    ResourceField(
      'kind',
      'Turi',
      type: FieldType.choice,
      required: true,
      createOnly: true,
      options: transactionKinds,
    ),
    ResourceField(
      'amount',
      "Summa (so'm)",
      type: FieldType.integer,
      required: true,
      createOnly: true,
      min: 0,
    ),
    ResourceField(
      'user_id',
      'Foydalanuvchi',
      type: FieldType.reference,
      reference: _userReference,
      createOnly: true,
    ),
    ResourceField(
      'status',
      'Holat',
      type: FieldType.choice,
      required: true,
      defaultValue: 'pending',
      options: _transactionStatuses,
    ),
    ResourceField('note', 'Izoh', type: FieldType.multiline),
  ],
);
