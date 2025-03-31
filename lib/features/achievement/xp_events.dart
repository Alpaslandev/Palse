/// XP kazandıran olay türlerini tanımlayan enum
/// Basitleştirilmiş versiyonu
enum XpEvent {
  // Tek seferlik görevler
  firstListing(500, 'first_listing_description', false, false),
  firstMessage(500, 'first_message_description', false, false),

  // Tekrarlanabilir görevler
  createListing(100, 'create_listing_description', true, false),
  sendMessage(35, 'send_first_message_description', true, false),
  receiveMessage(10, 'receive_first_message_description', true, false),
  writeComment(15, 'write_comment_description', true, false),
  receiveComment(10, 'receive_comment_description', true, false),

  // Günlük görevler
  dailyCreateListing(50, 'daily_create_listing_description', false, true),
  dailySendMessage(50, 'daily_send_message_description', false, true),
  dailyLogin(10, 'daily_login_description', false, true);

  /// Constructor
  const XpEvent(this.xpAmount, this.descriptionKey, this.isRepeatable, this.isDaily);

  /// Kazanılan XP miktarı
  final int xpAmount;

  /// Olay açıklaması için çeviri anahtarı
  final String descriptionKey;

  /// Görevin tekrarlanabilir olup olmadığı
  final bool isRepeatable;

  /// Görevin günlük görev olup olmadığı
  final bool isDaily;

  /// Görevi adından bulur
  static XpEvent? fromName(String name) {
    try {
      return XpEvent.values.firstWhere((event) => event.name == name || event.descriptionKey == name);
    } catch (e) {
      return null;
    }
  }

  /// Tüm günlük görevleri listeler
  static List<XpEvent> getDailyTasks() {
    return XpEvent.values.where((event) => event.isDaily).toList();
  }
}

/// XP event gruplarını tanımlayan enum
enum XpEventGroup {
  welcomeRewards(
      'welcome_rewards',
      [
        XpEvent.firstListing,
        XpEvent.firstMessage,
      ],
      '🎁'),

  listing(
      'listing',
      [
        XpEvent.createListing,
        XpEvent.receiveMessage,
      ],
      '📋'),

  messaging(
      'messaging',
      [
        XpEvent.sendMessage,
      ],
      '💬'),

  commenting(
      'commenting',
      [
        XpEvent.writeComment,
        XpEvent.receiveComment,
      ],
      '💭'),

  dailyTasks(
      'daily_tasks',
      [
        XpEvent.dailyCreateListing,
        XpEvent.dailySendMessage,
        XpEvent.dailyLogin,
      ],
      '📅');

  const XpEventGroup(this.titleKey, this.events, this.emoji);

  /// Grup başlığı için çeviri anahtarı
  final String titleKey;

  /// Bu gruba ait eventler
  final List<XpEvent> events;

  /// Grup için emoji
  final String emoji;

  /// Başlık anahtarına göre grup bulur
  static XpEventGroup? fromTitleKey(String titleKey) {
    try {
      return XpEventGroup.values.firstWhere((group) => group.titleKey == titleKey);
    } catch (e) {
      return null;
    }
  }

  /// Tüm görev gruplarını başlıklarına göre Map olarak döndürür
  static Map<String, List<XpEvent>> getAllTaskGroups() {
    final Map<String, List<XpEvent>> groups = {};
    for (final group in XpEventGroup.values) {
      groups[group.titleKey] = group.events;
    }
    return groups;
  }
}
