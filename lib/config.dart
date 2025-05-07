enum Environment { test, live }

class AppConfig {
  static Environment environment = Environment.test;

  // ---------- POSTGRES ----------
  static String get postgresApiBaseUrl {
    switch (environment) {
      case Environment.test:
        return 'https://www.barzzy.site/postgres-test-api';
      case Environment.live:
        return 'https://www.barzzy.site/postgres-live-api';
    }
  }

  static String get postgresWsBaseUrl {
    switch (environment) {
      case Environment.test:
        return 'wss://www.barzzy.site/postgres-test-ws';
      case Environment.live:
        return 'wss://www.barzzy.site/postgres-live-ws';
    }
  }

  // ---------- REDIS ----------
  static String get redisApiBaseUrl {
    switch (environment) {
      case Environment.test:
        return 'https://www.barzzy.site/redis-test-api';
      case Environment.live:
        return 'https://www.barzzy.site/redis-live-api';
    }
  }

  static String get redisWsBaseUrl {
    switch (environment) {
      case Environment.test:
        return 'wss://www.barzzy.site/redis-test-ws';
      case Environment.live:
        return 'wss://www.barzzy.site/redis-live-ws';
    }
  }
}