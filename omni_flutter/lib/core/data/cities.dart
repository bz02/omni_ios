/// A small offline gazetteer.
///
/// Birthplace matters twice over: latitude and longitude fix the ascendant, and
/// longitude corrects the clock to true solar time for the Ba Zi hour pillar.
/// Shipping a list beats calling a geocoder — it works on a plane, costs
/// nothing per lookup, and there is no third party to send a birth record to.
///
/// [standardUtcOffset] is the zone's *standard* offset. Summer time is not
/// modelled: doing it correctly needs the historical tz database, and getting
/// it silently wrong would shift an ascendant by a whole sign. The birth form
/// shows the offset and lets the user change it, which is the honest way to
/// handle a fact only they know.
library;

class City {
  const City(this.name, this.country, this.latitude, this.longitude,
      this.standardUtcOffset);

  final String name;
  final String country;

  /// Degrees north, negative for south.
  final double latitude;

  /// Degrees east, negative for west.
  final double longitude;

  final double standardUtcOffset;

  String get label => '$name, $country';

  /// Whether summer time is worth warning about for this zone.
  bool get observesSummerTime => const {
        'United States', 'Canada', 'United Kingdom', 'France', 'Germany',
        'Spain', 'Italy', 'Netherlands', 'Australia', 'New Zealand', 'Mexico',
        'Portugal', 'Ireland', 'Greece', 'Sweden', 'Poland', 'Austria',
        'Switzerland', 'Belgium', 'Denmark', 'Norway', 'Finland', 'Chile',
      }.contains(country);
}

/// Ordered so the app's two core markets sit at the top of an unfiltered list.
const List<City> cities = [
  // United States
  City('New York', 'United States', 40.7128, -74.0060, -5),
  City('Los Angeles', 'United States', 34.0522, -118.2437, -8),
  City('San Francisco', 'United States', 37.7749, -122.4194, -8),
  City('Chicago', 'United States', 41.8781, -87.6298, -6),
  City('Houston', 'United States', 29.7604, -95.3698, -6),
  City('Seattle', 'United States', 47.6062, -122.3321, -8),
  City('Boston', 'United States', 42.3601, -71.0589, -5),
  City('Atlanta', 'United States', 33.7490, -84.3880, -5),
  City('Miami', 'United States', 25.7617, -80.1918, -5),
  City('Dallas', 'United States', 32.7767, -96.7970, -6),
  City('Denver', 'United States', 39.7392, -104.9903, -7),
  City('Phoenix', 'United States', 33.4484, -112.0740, -7),
  City('Philadelphia', 'United States', 39.9526, -75.1652, -5),
  City('San Diego', 'United States', 32.7157, -117.1611, -8),
  City('Las Vegas', 'United States', 36.1699, -115.1398, -8),
  City('Portland', 'United States', 45.5152, -122.6784, -8),
  City('Austin', 'United States', 30.2672, -97.7431, -6),
  City('Detroit', 'United States', 42.3314, -83.0458, -5),
  City('Minneapolis', 'United States', 44.9778, -93.2650, -6),
  City('Honolulu', 'United States', 21.3069, -157.8583, -10),
  City('Anchorage', 'United States', 61.2181, -149.9003, -9),

  // Greater China
  City('Beijing', 'China', 39.9042, 116.4074, 8),
  City('Shanghai', 'China', 31.2304, 121.4737, 8),
  City('Guangzhou', 'China', 23.1291, 113.2644, 8),
  City('Shenzhen', 'China', 22.5431, 114.0579, 8),
  City('Chengdu', 'China', 30.5728, 104.0668, 8),
  City('Hangzhou', 'China', 30.2741, 120.1551, 8),
  City('Wuhan', 'China', 30.5928, 114.3055, 8),
  City("Xi'an", 'China', 34.3416, 108.9398, 8),
  City('Chongqing', 'China', 29.4316, 106.9123, 8),
  City('Nanjing', 'China', 32.0603, 118.7969, 8),
  City('Tianjin', 'China', 39.3434, 117.3616, 8),
  City('Shenyang', 'China', 41.8057, 123.4315, 8),
  City('Harbin', 'China', 45.8038, 126.5350, 8),
  City('Qingdao', 'China', 36.0671, 120.3826, 8),
  City('Xiamen', 'China', 24.4798, 118.0894, 8),
  City('Kunming', 'China', 25.0389, 102.7183, 8),
  City('Urumqi', 'China', 43.8256, 87.6168, 8),
  City('Kashgar', 'China', 39.4704, 75.9898, 8),
  City('Lhasa', 'China', 29.6520, 91.1721, 8),
  City('Hong Kong', 'Hong Kong', 22.3193, 114.1694, 8),
  City('Macau', 'Macau', 22.1987, 113.5439, 8),
  City('Taipei', 'Taiwan', 25.0330, 121.5654, 8),
  City('Kaohsiung', 'Taiwan', 22.6273, 120.3014, 8),

  // Rest of Asia
  City('Tokyo', 'Japan', 35.6762, 139.6503, 9),
  City('Osaka', 'Japan', 34.6937, 135.5023, 9),
  City('Seoul', 'South Korea', 37.5665, 126.9780, 9),
  City('Singapore', 'Singapore', 1.3521, 103.8198, 8),
  City('Bangkok', 'Thailand', 13.7563, 100.5018, 7),
  City('Kuala Lumpur', 'Malaysia', 3.1390, 101.6869, 8),
  City('Jakarta', 'Indonesia', -6.2088, 106.8456, 7),
  City('Manila', 'Philippines', 14.5995, 120.9842, 8),
  City('Ho Chi Minh City', 'Vietnam', 10.8231, 106.6297, 7),
  City('Hanoi', 'Vietnam', 21.0278, 105.8342, 7),
  City('Mumbai', 'India', 19.0760, 72.8777, 5.5),
  City('Delhi', 'India', 28.7041, 77.1025, 5.5),
  City('Bangalore', 'India', 12.9716, 77.5946, 5.5),
  City('Dubai', 'United Arab Emirates', 25.2048, 55.2708, 4),
  City('Karachi', 'Pakistan', 24.8607, 67.0011, 5),

  // Europe
  City('London', 'United Kingdom', 51.5074, -0.1278, 0),
  City('Manchester', 'United Kingdom', 53.4808, -2.2426, 0),
  City('Dublin', 'Ireland', 53.3498, -6.2603, 0),
  City('Paris', 'France', 48.8566, 2.3522, 1),
  City('Berlin', 'Germany', 52.5200, 13.4050, 1),
  City('Munich', 'Germany', 48.1351, 11.5820, 1),
  City('Amsterdam', 'Netherlands', 52.3676, 4.9041, 1),
  City('Madrid', 'Spain', 40.4168, -3.7038, 1),
  City('Barcelona', 'Spain', 41.3851, 2.1734, 1),
  City('Rome', 'Italy', 41.9028, 12.4964, 1),
  City('Milan', 'Italy', 45.4642, 9.1900, 1),
  City('Lisbon', 'Portugal', 38.7223, -9.1393, 0),
  City('Zurich', 'Switzerland', 47.3769, 8.5417, 1),
  City('Vienna', 'Austria', 48.2082, 16.3738, 1),
  City('Stockholm', 'Sweden', 59.3293, 18.0686, 1),
  City('Copenhagen', 'Denmark', 55.6761, 12.5683, 1),
  City('Oslo', 'Norway', 59.9139, 10.7522, 1),
  City('Warsaw', 'Poland', 52.2297, 21.0122, 1),
  City('Athens', 'Greece', 37.9838, 23.7275, 2),
  City('Moscow', 'Russia', 55.7558, 37.6173, 3),
  City('Istanbul', 'Turkey', 41.0082, 28.9784, 3),

  // Americas beyond the US
  City('Toronto', 'Canada', 43.6532, -79.3832, -5),
  City('Vancouver', 'Canada', 49.2827, -123.1207, -8),
  City('Montreal', 'Canada', 45.5017, -73.5673, -5),
  City('Mexico City', 'Mexico', 19.4326, -99.1332, -6),
  City('Sao Paulo', 'Brazil', -23.5505, -46.6333, -3),
  City('Rio de Janeiro', 'Brazil', -22.9068, -43.1729, -3),
  City('Buenos Aires', 'Argentina', -34.6037, -58.3816, -3),
  City('Santiago', 'Chile', -33.4489, -70.6693, -4),
  City('Lima', 'Peru', -12.0464, -77.0428, -5),
  City('Bogota', 'Colombia', 4.7110, -74.0721, -5),

  // Oceania, Africa, Middle East
  City('Sydney', 'Australia', -33.8688, 151.2093, 10),
  City('Melbourne', 'Australia', -37.8136, 144.9631, 10),
  City('Brisbane', 'Australia', -27.4698, 153.0251, 10),
  City('Perth', 'Australia', -31.9505, 115.8605, 8),
  City('Auckland', 'New Zealand', -36.8485, 174.7633, 12),
  City('Cairo', 'Egypt', 30.0444, 31.2357, 2),
  City('Lagos', 'Nigeria', 6.5244, 3.3792, 1),
  City('Nairobi', 'Kenya', -1.2921, 36.8219, 3),
  City('Johannesburg', 'South Africa', -26.2041, 28.0473, 2),
  City('Tel Aviv', 'Israel', 32.0853, 34.7818, 2),
];

/// Case-insensitive search over city and country.
List<City> searchCities(String query, {int limit = 20}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return cities.take(limit).toList();

  final startsWith = <City>[];
  final contains = <City>[];
  for (final city in cities) {
    final name = city.name.toLowerCase();
    if (name.startsWith(q)) {
      startsWith.add(city);
    } else if (name.contains(q) || city.country.toLowerCase().contains(q)) {
      contains.add(city);
    }
  }
  return [...startsWith, ...contains].take(limit).toList();
}

City? cityByLabel(String label) {
  for (final city in cities) {
    if (city.label == label) return city;
  }
  return null;
}
