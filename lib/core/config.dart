/// Raw URL of the market.json the daily GitHub Action commits, e.g.
/// `https://raw.githubusercontent.com/USER/investment_helper/main/data/market.json`
///
/// Pass it at build time: `flutter run --dart-define=DATA_URL=...`
/// When empty the app uses its cached copy or the bundled sample.
const dataUrl = String.fromEnvironment('DATA_URL');
