import '../../../core/config/app_info.dart';

class LegalSection {
  final String heading;
  final List<String> paragraphs;

  const LegalSection(this.heading, this.paragraphs);
}

class LegalDocument {
  final String title;
  final List<LegalSection> sections;

  const LegalDocument(this.title, this.sections);
}

const LegalDocument privacyPolicy = LegalDocument('Privacy policy', [
  LegalSection('About this policy', [
    'ShopLite is a practice app built to learn mobile development. This policy '
        'explains what the app stores on your phone and what it sends over the internet.',
  ]),
  LegalSection('What is stored on your phone', [
    'Your cart, saved addresses (names, mobile numbers and delivery addresses), '
        'wishlist, orders, the name and number you edit in your profile, products you '
        'viewed recently, your recent searches, reviews you write, which notifications '
        'you have read, and your theme choice.',
    'Your sign-in tokens are kept in the phone\'s secure storage.',
    'This data stays on your phone. The app has no server of its own and does not '
        'upload it anywhere.',
  ]),
  LegalSection('What is sent over the internet', [
    'When you sign in, your username and password are sent over HTTPS to the demo '
        'server at dummyjson.com, a public test service. Requests for products, '
        'categories, searches and reviews go to the same server.',
    'Product pictures are loaded from that service\'s image host. Like any website, '
        'these servers can see your IP address.',
    'The app does not send anything else. It has no analytics, no advertising and no '
        'crash reporting.',
  ]),
  LegalSection('Security', [
    'Sign-in tokens are encrypted by the phone. Other data, such as addresses and '
        'orders, is stored on the phone without extra encryption and is protected by '
        'your phone\'s own lock and app isolation.',
  ]),
  LegalSection('Your choices', [
    'In Settings, "Delete my data" removes everything above for your account from '
        'this phone and signs you out. You can also clear your recent searches and '
        'recently viewed products from the places they appear. Uninstalling the app '
        'removes all of its data.',
    'Your test account on the demo server is not affected, because this app cannot '
        'change it.',
  ]),
  LegalSection('Changes and questions', [
    'If the app changes in a way that affects this policy, this page will change '
        'too. Last updated: ${AppInfo.legalUpdated}.',
    'Questions or problems can be raised on the project page: ${AppInfo.sourceUrl}.',
  ]),
]);

const LegalDocument termsOfUse = LegalDocument('Terms of use', [
  LegalSection('A practice app', [
    'ShopLite is a learning project, not a real shop. There is no real stock, no real '
        'prices and no real delivery.',
  ]),
  LegalSection('No real purchases', [
    'Orders you place are saved on your phone only. No money is charged, no card '
        'details are collected, and nothing is shipped. Order statuses are simulated.',
  ]),
  LegalSection('Accounts', [
    'Sign-in works with the demo server\'s test accounts. You cannot create an '
        'account or reset a password in this app.',
  ]),
  LegalSection('Content', [
    'Product information, pictures and customer reviews come from a public test '
        'service and are made up. They do not describe real products.',
  ]),
  LegalSection('No warranty', [
    'The app is provided as it is, without any promise that it works without '
        'errors or stays available.',
  ]),
  LegalSection('Changes', [
    'These terms may change as the app changes. Last updated: ${AppInfo.legalUpdated}.',
  ]),
]);
