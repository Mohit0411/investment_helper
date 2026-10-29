/// Where the app fetches the market.json the daily GitHub Action commits.
///
/// Override at build time: `flutter run --dart-define=DATA_URL=...`
/// An empty value makes the app use its cached copy or the bundled sample.
const dataUrl = String.fromEnvironment(
  'DATA_URL',
  defaultValue: 'https://raw.githubusercontent.com/Mohit0411/investment_helper/main/data/market.json',
);
