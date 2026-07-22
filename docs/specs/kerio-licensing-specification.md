# Kerio Connect — Спецификация системы лицензирования

Бинарный файл: `/opt/kerio/mailserver/mailserver` (~66 MB ELF x86_64)

Все адреса — виртуальные адреса в ELF-бинарнике. Префикс пространства имён: `kerio::crypto::`除非 указано иное.

---

## 1. Назначение системы

Система лицензирования Kerio Connect обеспечивает:

1. **Криптографическую защиту** — RSA1024 + MD5 подпись лицензионного файла
2. **Идентификацию продукта** — привязка лицензии к конкретному продукту (Connect, Operator, Control и др.)
3. **Временной контроль** — даты истечения лицензии и подписки
4. **Ёмкостной контроль** — ограничение количества пользователей
5. **Управление функциями** — включение/отключение модулей (Sophos, ActiveSync, Anti-spam, Greylisting)
6. **Привязку к домену** — связь лицензии с конкретным доменом
7. **Совместимость версий** — минимальная версия сервера
8. **Автоматическое обновление** — периодическая проверка/обновление лицензии
9. **Trial-менеджмент** — генерация и отслеживание пробных лицензий
10. **Кластерную поддержку** — отслеживание лицензий в multi-node
11. **Интеграцию с third-party** — лицензии BitDefender Anti-spam, Greylisting
12. **Оповещения** — уведомления о состоянии лицензии
12. **SaaS-репортинг** — отчётность об использовании лицензий

---

## 2. Типовые задачи системы лицензирования

| # | Типовая задача | Описание | Источник |
|---|---|---|---|
| T1 | Генерация лицензий | Создание криптографически подписанных лицензионных ключей | RLM, Sentinel EMS, CodeMeter |
| T2 | Распространение | Доставка лицензии клиенту (email, портал, авто-загрузка) | RLM, Sentinel EMS, CodeMeter |
| T3 | Активация | Привязка лицензии к конкретному机器у/домену | Sentinel EMS, SoftActivate, LicenseSeat |
| T4 | Валидация | Проверка подлинности и бизнес-правил лицензии | RLM, FlexNet, Laravel License Core |
| T5 | Принудительное ограничение | Ограничение функциональности по состоянию лицензии | Все системы |
| T6 | Обновление/продление | Расширение или обновление действующей лицензии | CodeMeter, Sentinel EMS |
| T7 | Отзыв (Revocation) | Аннулирование скомпрометированных лицензий | Sentinel EMS, CodeMeter |
| T8 | Мониторинг | Отслеживание использования и соответствия | Sentinel EMS, CodeMeter |
| T9 | Отчётность | Статистика, оповещения, аудит | Sentinel EMS, CodeMeter |
| T10 | Переносимость | Перенос лицензий между машинами | Sentinel EMS, CodeMeter, RLM |
| T11 | Grace Period | Обработка временных сбоев без блокировки | Laravel License Core |
| T12 | Анти-пиратство | Предотвращение несанкционированного использования | Все системы |
| T13 | Управление функциями | Контроль доступа к конкретным возможностям | FlexNet, CodeMeter |
| T14 | Trial-менеджмент | Управление пробными периодами | Все системы |
| T15 | Подписка | Привязка лицензий к платежам/подпискам | RLM, Sentinel EMS |

---

## 3. Распределение артефактов по типовым задачам

### T1: Генерация лицензий

| Артефакт | Адрес/Расположение | Назначение |
|---|---|---|
| `KLicensePubKey` | `0x1581080` | Конструктор RSA1024-ключа (260 байт) |
| `KLicenseManager::make_trial_license` | `0x1582c20` | Генерация trial-лицензии |
| `KLicense::parseMainData` | `0x15826b0` | Парсинг полей лицензии |
| `KLicense::fixProductID` | `0x1581e30` | Нормализация Product ID |
| `KLicenseInternal::list` | `0x1581cf0` | Сериализация лицензии в строку |
| Формат лицензии | Секции `--LICENSE--` и `--PRODUCT-LICENSE--` | Двухсекционный формат с Feature-блоками |
| `KMS::ServerManFacade::getLicenseExtensionsList` | `0xf526c0` | Список расширений лицензии |

### T2: Распространение

| Артефакт | Адрес/Расположение | Назначение |
|---|---|---|
| `LicenseDownloader` | `0x20160f0` | Конструктор, парсинг HTTP-заголовков |
| `LicenseDownloader::parse_reply_code` | `0x2016bb0` | Парсинг ответа сервера |
| `RegistrationManager::installLicense` | `0x2005580` | Установка скачанной лицензии |
| `ProductRegistration.start` | API | Инициализация регистрации |
| `ProductRegistration.finish` | API | Завершение регистрации, получение лицензии |
| `Server.uploadLicense` | API | Прямая загрузка лицензионного файла |
| Эндпоинты | `register.kerio.com`, `trial.kerio.com` | Серверы регистрации |
| HTTP-заголовки | `X-Kerio-Desc`, `X-Kerio-Token`, `X-Kerio-Response` | Заголовки API |
| MIME-типы | `application/x-kerio-license`, `application/x-kerio-registration`, `application/x-kerio-trial` | Типы контента |

### T3: Активация

| Артефакт | Адрес/Расположение | Назначение |
|---|---|---|
| `KLicenseManager::admin_set_license` | `0x1584780` | Установка лицензии через Admin UI |
| `KLicenseInternal::install` | `0x157f8d0` | Низкоуровневая установка после скачивания |
| `Registration::setLicenseCallback` | `0x4526f0` | Установка callback-функции лицензии |
| `LicenseManagerInitializer::initImpl` | `0x4402b0` | Инициализация менеджера лицензий |
| Привязка к домену | `initial_check_license` | Проверка домена против лицензии |

### T4: Валидация

| Артефакт | Адрес/Расположение | Назначение |
|---|---|---|
| `KLicense::checkLicenseSignature` | `0x1583f30` | Верификация подписи (RSA1024 + MD5) |
| `KLicenseManager::check_license` | `0x15821a0` | 9-шаговая проверка бизнес-правил |
| `KLicenseManager::initial_check_license` | `0x1582450` | Расширенная цепочка проверки |
| `KLicenseManager::isLicenseOk` | `0x157f890` | Обёртка для проверки состояния |
| `KLicenseManager::checkMinimalVersion` | `0x15819f0` | Парсинг `"%d.%d.%d"`, сравнение версий |
| `RSAPublicDecrypt` | `0x15814f0` | RSA-дешифрование 128-байтного блока |
| `RSAPublicBlock` | `0x1580f10` | Ядро модульного exponentiation |
| `convertDataToMD5Stream` | `0x1581be0` | Вычисление MD5 |
| `load_check_license` | `0x436240` | Точная входная точка загрузки+проверки |
| `simplifyLicenseCheckResult` | `0x8b41a0` | Нормализация кодов возврата |
| Коды возврата | 0-5 | 7 уникальных кодов |
| API-константы | 10 констант | Состояния валидации |

### T5: Принудительное ограничение

| Артефакт | Адрес/Расположение | Назначение |
|---|---|---|
| `KLicenseManager::licenseOk` | `0x157f850` | Установка state=1, вызов OK-callback |
| `KLicenseManager::licenseFail` | `0x157f860` | Установка state=0, вызов Fail-callback |
| `KLicenseManager::defaultOkFunction` | `0x157f870` | Дефолтный OK-callback (возвращает 1) |
| RC=5 (degraded mode) | `check_license` | Сервер работает в ограниченном режиме |
| `LicenseCheckForwardingEnabled` | API-константа | Проверка влияет на пересылку почты |
| `LicenseLimit` | API-константа | Достигнут лимит пользователей |
| `LicenseTooManyUsers` | API-константа | Активных пользователей больше лицензии |

### T6: Обновление/продление

| Артефакт | Адрес/Расположение | Назначение |
|---|---|---|
| `AutomaticLicenseUpdater::tryLicenseUpdate` | `0x1ffc470` | Периодическая проверка обновлений |
| `getAutoLicenseUpdatePeriod` | `0x8c9fb0` | Чтение интервала авто-обновления |
| `licenseUpdateDoneCb` | `0x8ca080` | Callback завершения асинхронного обновления |
| `dbfuncResetLicenseUpdatePeriod` | `0x8c9fe0` | Сброс таймера обновления |
| `AutomaticLicenseManager::checkLicense` | `0x1581650` | Периодическая верификация |
| `AutomaticLicenseUpdater::UPDATE_ALREADY_IN_PROGRESS` | `0x39e13e0` | Флаг: обновление выполняется |
| `AutomaticLicenseUpdater::threadIsRunning` | `0x39e13e8` | Флаг: поток запущен |
| `AutomaticLicenseUpdater::quitImmediatelly` | `0x39e13ec` | Флаг: немедленное завершение |
| `AutomaticLicenseUpdater::config` | `0x39e13f0` | Конфигурация авто-обновления |
| `AutomaticLicenseUpdater::th` | `0x39e1400` | Поток обновления |
| `AutomaticLicenseUpdater::protector` | `0x39e1420` | Мьютекс защиты |
| `AutomaticLicenseUpdater::abortCommand` | `0x39e1450` | Команда прерывания |

### T7: Отзыв (Revocation)

**Не покрыто** — отсутствуют функции отзыва/аннулирования лицензий. Это логично для серверного продукта.

### T8: Мониторинг

| Артефакт | Адрес/Расположение | Назначение |
|---|---|---|
| `license_hook` | `0x8cf9a0` | TinyDB-hook для изменений лицензии |
| `dbfunc_set_license` | `0x8ceea0` | TinyDB-функция установки лицензии |
| TinyDB-переменные | 11 полей | Хранение данных лицензии в БД |
| `getLicenseExpiresLocalTime` | `0x8cc4f0` | Конвертация срока в локальное время |
| `RPCClientMaster::getLicenseUsers` | `0x21f7c20` | Получение пользователей лицензии в кластере |
| `ClusterDirEngineBridge::getLicenseUsersOnMaster` | `0x21ed510` | Получение пользователей на master-узле |
| `ClusterDirEngineBridge::licenseTrackerCallback` | `0x39e3550` | Callback отслеживания лицензий |
| `ClusterDirEngineBridge::licenseTrackerMasterCallback` | `0x39e3560` | Callback master-отслеживания |
| `RPCClientMaster::csGetLicenseUsers` | `0x39e3690` | Critical section для getLicenseUsers |
| `RPCClientMaster::csShowTrackedLicensedUsers` | `0x39e36a0` | Critical section для tracked users |
| `RPCClientMaster::csShowTrackedLicensedUsersCount` | `0x39e3698` | Critical section для tracked users count |
| `RPCClientSlave::csClearUserLicenseDDIndexes` | `0x39e4518` | Critical section для очистки индексов |

### T9: Отчётность

| Артефакт | Адрес/Расположение | Назначение |
|---|---|---|
| `getLicenseAlert` | `0x8b45b0` | Генерация оповещений о лицензии |
| `getUsersAlert` | `0x8b4280` | Оповещения о превышении лимита пользователей |
| `getStorageAlert` | `0x8b43f0` | Оповещения о хранилище |
| `getAlerts` | `0x8b4860` | Сбор всех оповещений |
| `dbfunc_get_alerts` | `0x8b4ce0` | TinyDB-функция получения оповещений |
| `KMS::ServerManFacade::getAlertList` | `0xf52740` | JSON API для списка оповещений |
| `kerio::saas::SaasReporter` | singleton | SaaS-репортинг лицензий |
| `LicenseUsageReport::LICENSE_USAGE_NAME` | `0x39b35d8` | Имя отчёта об использовании |
| `LicenseUsageReport::LICENSE_USAGE_VERSION_NAME` | `0x39b35e0` | Имя версии отчёта |
| `LicenseUsageReport::LICENSE_USAGE_VERSION` | `0x39b35e8` | Версия отчёта |
| `ClusterDir::Slave::GetSaasStatisticsReport` | `0x221a1b0` | SaaS-статистика в кластере |
| `UserLicenseTrackerCallback::getSaasStatisticsReportForMaster` | `0x4d9fe0` | SaaS-статистика для master-узла |

### T10: Переносимость

**Не покрыто** — отсутствуют функции переноса лицензий между машинами (rehosting). Это логично для серверного продукта.

### T11: Grace Period

**Не покрыто** — отсутствует логика отсрочки при истечении.

### T12: Анти-пиратство

| Артефакт | Адрес/Расположение | Назначение |
|---|---|---|
| RSA1024-подпись | `KLicensePubKey` | 1024-битный RSA-ключ |
| MD5-хеш | `convertDataToMD5Stream` | Хеш данных между маркерами |
| Проверка целостности | `checkLicenseSignature` | Сравнение 16 байт RSA-дешифрования с MD5 |
| `LicenseParserException` | `0x39b2e38` | Исключение при ошибках парсинга |
| `KLicenseManager::DEFAULT_LICENSE_FILENAME` | `0x39b2e30` | Имя файла лицензии по умолчанию |

### T13: Управление функциями

| Артефакт | Адрес/Расположение | Назначение |
|---|---|---|
| Feature-блоки | Sophos, ActiveSync, Kerio Anti-spam | Суб-лицензии в `--PRODUCT-LICENSE--` |
| `Features` поле | Лицензионный файл | Список функций через запятую |
| `BitDefenderAntispamLicense.cpp` | Исходный файл | Модуль лицензии BitDefender |
| `SpamModule::isBitDefenderLicensed` | `0x51e540` | Проверка лицензии BitDefender |
| `computeLicenseValidity` | `0x532900` | Вычисление валидности лицензии BitDefender |
| `activesync::LicenseManager::isLicensed` | `0x1ede410` | Проверка лицензии ActiveSync |
| `activesync::LicenseManager::setLicensed` | `0x1eddf90` | Установка статуса лицензии ActiveSync |
| `activesync::LicenseManager::checkLicense` | `0x1ede240` | Валидация лицензии ActiveSync |
| `activesync::licenseManager` | `0x383f758` | Синглтон ActiveSync-лицензии |
| `BdaLicenseManager::getInstance` | `0x532c60` | Синглтон BitDefender-лицензии |
| `BdaLicenseManager::checkLicense` | `0x532b00` | Валидация лицензии BitDefender |
| `BdaLicenseManager::featureName` | `0x39c2798` | Имя функции BitDefender |
| `GreylistLicenseMan::isLicensed` | `0x58e8c0` | Проверка лицензии greylisting |
| `GreylistLicenseMan::checkLicense` | `0x58ea50` | Валидация лицензии greylisting |
| `GreylistLicenseMan::computeLicenseValidity` | `0x58e970` | Вычисление валидности greylisting |
| `GreylistLicenseMan::greylistLicenseManager` | `0x39c2d90` | Синглтон greylist-лицензии |

### T14: Trial-менеджмент

| Артефакт | Адрес/Расположение | Назначение |
|---|---|---|
| `KLicenseManager::make_trial_license` | `0x1582c20` | Генерация trial-лицензии |
| `check_promo_license` | `0x436bd0` | Валидация промо-лицензии |
| `License-Type: Trial` | Лицензионный файл | Тип лицензии |
| `TinydbLicenseVariableTrialID` | TinyDB | ID trial-лицензии в БД |
| `trial.kerio.com` | Эндпоинт | Сервер активации trial |

### T15: Подписка

| Артефакт | Адрес/Расположение | Назначение |
|---|---|---|
| `Subscription-Expires` | Лицензионный файл | Срок действия подписки |
| RC=4 | `check_license` | Проверка подписки (step 7) |
| `LicenseSoonExpire` | API-константа | Скоро истекает подписка |

---

## 4. Артефакты, не вошедшие в типовые задачи

| # | Артефакт | Адрес/Расположение | Возможное назначение | Примечание |
|---|---|---|---|---|
| 1 | `ClusterDir::Slave/Master::*` (4 функции) | `0x22198a0`, `0x2247020`, `0x224c8f0`, `0x2246b00` | Кластерная синхронизация лицензий | Специфично для multi-node развёртывания |
| 2 | `GreylistLicenseMan.cpp` | Исходный файл | Лицензия модуля greylisting | Отдельный подмодуль |
| 3 | `UserLicenseTracker*.cpp` (3 файла) | Исходные файлы | Отслеживание привязки пользователей | Внутренняя оптимизация |
| 4 | `computeLicenseValidity` (0x532900) | Адрес | Валидация лицензии BitDefender | Third-party интеграция |
| 5 | `License-Version: 2`, `Format-Version: 1` | Лицензионный файл | Миграция формата лицензий | Механизм эволюции формата |
| 6 | `KLicenseInternal::setNullLicense` | `0x157f7f0` | Инициализация пустого состояния | Внутренняя реализация |
| 7 | `defaultOkFunction` | `0x157f870` | Дефолтный callback-обработчик | Внутренняя реализация |
| 8 | `Host-ID` (опциональное поле) | Лицензионный файл | Привязка к аппаратному ID | Опциональный механизм |
| 9 | `Antivirus-Expires` | Лицензионный файл | Отдельный срок антивируса | Суб-подписка в рамках основной лицензии |
| 10 | `LicenseParserException` | `0x39b2e38` | Исключение при ошибках парсинга | Механизм обработки ошибок |
| 11 | `license_manager` | `0x39e5088` | Синглтон менеджера лицензий | Глобальная точка доступа |
| 12 | `licenseUpdatePeriod` | `0x39aa850` | Конфигурация интервала обновления | Глобальная переменная |
| 13 | `SaasImpl.cpp` | Исходный файл | SaaS-реализация | Third-party интеграция |
| 14 | `SaasReporter.cpp` | Исходный файл | SaaS-репортинг | Third-party интеграция |
| 15 | `alerts.cpp` | Исходный файл | Система оповещений | Механизм уведомлений |

---

## 5. Сводная таблица покрытия

| Типовая задача | Покрытие | Кол-во артефактов | Статус |
|---|---|---|---|
| T1: Генерация | Частичное | 7 | Генерация trial есть, полная генерация на стороне vendor |
| T2: Распространение | Полное | 9 | Все компоненты доставки найдены |
| T3: Активация | Полное | 5 | Все компоненты активации найдены |
| T4: Валидация | Полное | 11 | Полная цепочка верификации |
| T5: Принудительное ограничение | Полное | 7 | Все механизмы ограничения найдены |
| T6: Обновление | Полное | 12 | Полный цикл авто-обновления |
| T7: Отзыв | **Не покрыто** | 0 | Отсутствует в Kerio Connect |
| T8: Мониторинг | Полное | 12 | Все механизмы мониторинга найдены |
| T9: Отчётность | Полное | 12 | Оповещения + SaaS-репортинг |
| T10: Переносимость | **Не покрыто** | 0 | Отсутствует в Kerio Connect |
| T11: Grace Period | **Не покрыто** | 0 | Отсутствует в Kerio Connect |
| T12: Анти-пиратство | Полное | 5 | RSA1024 + MD5 + исключения |
| T13: Управление функциями | Полное | 16 | Все модули найдены |
| T14: Trial-менеджмент | Полное | 5 | Полный цикл trial |
| T15: Подписка | Полное | 3 | Все компоненты подписки |
| **Итого** | **13/15** | **~120** | **87% покрытие** |

---

## 6. Функциональные блоки

### 6.1 Ядро лицензирования (kerio::crypto)

| Функция | Адрес | Описание |
|---|---|---|
| `KLicensePubKey` | `0x1581080` | Конструктор RSA1024-ключа |
| `RSAPublicDecrypt` | `0x15814f0` | RSA-дешифрование |
| `RSAPublicBlock` | `0x1580f10` | Модульный exponentiation |
| `convertDataToMD5Stream` | `0x1581be0` | Вычисление MD5 |
| `KLicense::checkLicenseSignature` | `0x1583f30` | Верификация подписи |
| `KLicense::findLicenseBeginning` | `0x1583940` | Поиск маркера `--LICENSE--` |
| `KLicense::loadFrom` | `0x15838c0` | Загрузка содержимого |
| `KLicense::parseMainData` | `0x15826b0` | Парсинг key-value полей |
| `KLicense::fixProductID` | `0x1581e30` | Нормализация Product ID |
| `KLicenseInternal::list` | `0x1581cf0` | Сериализация в строку |
| `KLicenseInternal::setNullLicense` | `0x157f7f0` | Инициализация null-состояния |
| `KLicenseInternal::checkLicense` | `0x157f8d0` | Внутренняя проверка |

### 6.2 Менеджер лицензий (kerio::crypto::KLicenseManager)

| Функция | Адрес | Описание |
|---|---|---|
| `checkMinimalVersion` | `0x15819f0` | Парсинг `"%d.%d.%d"`, сравнение версий |
| `isLicenseOk` | `0x157f890` | Проверка состояния лицензии |
| `check_license` | `0x15821a0` | 9-шаговая проверка бизнес-правил |
| `initial_check_license` | `0x1582450` | Расширенная цепочка проверки |
| `load_license` | `0x1582de0` | Загрузка из файла |
| `admin_set_license` | `0x1584780` | Установка через Admin UI |
| `make_trial_license` | `0x1582c20` | Генерация trial |
| `licenseOk` | `0x157f850` | Установка state=1 + OK-callback |
| `licenseFail` | `0x157f860` | Установка state=0 + Fail-callback |
| `defaultOkFunction` | `0x157f870` | Дефолтный OK-callback |

### 6.3 Дата/время

| Функция | Адрес | Описание |
|---|---|---|
| `read_date` | `0x1581ab0` | Парсинг `"%d %s %d"` → `time_t` |
| `getLicenseExpiresLocalTime` | `0x8cc4f0` | Конвертация в локальное время |

### 6.4 Жизненный цикл

| Функция | Адрес | Описание |
|---|---|---|
| `load_check_license` | `0x436240` | Точная входная точка |
| `simplifyLicenseCheckResult` | `0x8b41a0` | Нормализация кодов |
| `check_promo_license` | `0x436bd0` | Валидация промо-лицензии |
| `license_hook` | `0x8cf9a0` | TinyDB-hook |
| `dbfunc_set_license` | `0x8ceea0` | TinyDB-функция установки |
| `LicenseManagerInitializer::initImpl` | `0x4402b0` | Инициализация |
| `LicenseManagerInitializer::closeImpl` | `0x43d8f0` | Завершение |

### 6.5 Авто-обновление

| Функция | Адрес | Описание |
|---|---|---|
| `LicenseDownloader` | `0x20160f0` | Конструктор |
| `LicenseDownloader::parse_reply_code` | `0x2016bb0` | Парсинг ответа |
| `RegistrationManager::installLicense` | `0x2005580` | Установка скачанной лицензии |
| `AutomaticLicenseUpdater::tryLicenseUpdate` | `0x1ffc470` | Периодическая проверка |
| `AutomaticLicenseManager::checkLicense` | `0x1581650` | Периодическая верификация |
| `getAutoLicenseUpdatePeriod` | `0x8c9fb0` | Чтение интервала |
| `licenseUpdateDoneCb` | `0x8ca080` | Callback завершения |
| `dbfuncResetLicenseUpdatePeriod` | `0x8c9fe0` | Сброс таймера |
| `Registration::setLicenseCallback` | `0x4526f0` | Установка callback |

### 6.6 Third-party лицензии

| Функция | Адрес | Описание |
|---|---|---|
| `SpamModule::isBitDefenderLicensed` | `0x51e540` | Проверка BitDefender |
| `computeLicenseValidity` (anonymous) | `0x532900` | Валидация BitDefender |
| `BdaLicenseManager::getInstance` | `0x532c60` | Синглтон BitDefender |
| `BdaLicenseManager::checkLicense` | `0x532b00` | Проверка BitDefender |
| `activesync::LicenseManager::isLicensed` | `0x1ede410` | Проверка ActiveSync |
| `activesync::LicenseManager::setLicensed` | `0x1eddf90` | Установка ActiveSync |
| `activesync::LicenseManager::checkLicense` | `0x1ede240` | Валидация ActiveSync |
| `GreylistLicenseMan::isLicensed` | `0x58e8c0` | Проверка greylisting |
| `GreylistLicenseMan::checkLicense` | `0x58ea50` | Валидация greylisting |
| `GreylistLicenseMan::computeLicenseValidity` | `0x58e970` | Валидность greylisting |

### 6.7 Кластер

| Функция | Адрес | Описание |
|---|---|---|
| `ClusterDir::Slave::ClearUserLicenseDDIndexes` | `0x22198a0` | Очистка индексов на slave |
| `ClusterDir::Master::GetUserLicenseIndex` | `0x2247020` | Получение индекса на master |
| `ClusterDir::Master::ShowTrackedLicensedUsers` | `0x224c8f0` | Список tracked users |
| `ClusterDir::Master::ShowTrackedLicensedUsersCount` | `0x2246b00` | Количество tracked users |
| `RPCClientMaster::getLicenseUsers` | `0x21f7c20` | Получение пользователей |
| `ClusterDirEngineBridge::getLicenseUsersOnMaster` | `0x21ed510` | Пользователи на master |
| `ClusterDir::Slave::GetSaasStatisticsReport` | `0x221a1b0` | SaaS-статистика |

### 6.8 Оповещения и отчётность

| Функция | Адрес | Описание |
|---|---|---|
| `getLicenseAlert` | `0x8b45b0` | Оповещения о лицензии |
| `getUsersAlert` | `0x8b4280` | Оповещения о пользователях |
| `getStorageAlert` | `0x8b43f0` | Оповещения о хранилище |
| `getAlerts` | `0x8b4860` | Сбор всех оповещений |
| `dbfunc_get_alerts` | `0x8b4ce0` | TinyDB-функция оповещений |
| `KMS::ServerManFacade::getAlertList` | `0xf52740` | JSON API оповещений |
| `KMS::ServerManFacade::getLicenseExtensionsList` | `0xf526c0` | Список расширений |

---

## 7. Структуры данных

### 7.1 Формат лицензионного файла

```
--LICENSE--
<key-value pairs>
--SIGNATURE--
<256 hex chars (128 bytes RSA signature)>
--END--

--PRODUCT-LICENSE--
<key-value pairs>
<Feature-Begin: name> ... <Feature-End: name>
--SIGNATURE--
<256 hex chars (128 bytes RSA signature)>
--PRODUCT-END--
```

### 7.2 Поля лицензии

**Секция A (`--LICENSE--`):**

| Поле | Описание | Пример |
|---|---|---|
| `Base-ID` | Уникальный ID лицензии | `10512-ABL31-8WJ6H` |
| `Product` | Имя продукта | `Kerio MailServer` |
| `License-Expires` | Срок действия лицензии | `04 May 2026` |
| `Subscription-Expires` | Срок подписки | `04 May 2026` |
| `Users` | Макс. количество пользователей | `25` |
| `OS` | Целевая ОС | `Linux` |
| `Company` | Организация | `HomeLab` |
| `E-Mail` | Email регистранта | `foksk76@gmail.com` |
| `Features` | Список функций | `AV-SOPHOS` |
| `Antivirus-Expires` | Срок антивируса | `04 May 2026` |
| `Add-On-ID` | ID дополнения | `10512-ABL31-8WJ6H` |

**Секция B (`--PRODUCT-LICENSE--`):**

Все поля секции A, плюс:

| Поле | Описание | Пример |
|---|---|---|
| `Product-ID` | Числовой ID продукта | `1` |
| `License-Type` | Тип лицензии | `Trial` |
| `License-Version` | Версия формата лицензии | `2` |
| `Format-Version` | Версия формата файла | `1` |
| `Person` | (опционально) Имя | — |
| `Host-ID` | (опционально) Аппаратный ID | — |
| `Edition` | (опционально) Редакция | — |
| `Version` | (опционально) Версия | — |
| `Min-Version` | (опционально) Минимальная версия | — |

### 7.3 Feature-блоки

```
Feature-Begin: <feature-name>
License-Expires: <date>
Subscription-Expires: <date>
Users: <max>
ID: <base-id>
Feature-End: <feature-name>
```

Известные имена: `Sophos`, `ActiveSync`, `Kerio Anti-spam`.

### 7.4 Формат дат

Все даты: `"%d %s %d"` (день месяц-строкой год), например: `04 May 2026`.

### 7.5 Product ID enum

| ID | Продукт |
|---|---|
| 0 | Unknown |
| 1 | Kerio Connect |
| 2 | Kerio Operator |
| 3 | Kerio Control |
| 4 | Kerio WinRoute Firewall |
| 5 | Kerio Control UTM |
| 6 | Kerio Outlook Connector |
| 7 | Kerio Client |
| 8 | Kerio Connect ActiveSync |

### 7.6 Коды возврата check_license

| Код | Условие | Строка ошибки |
|---|---|---|
| 0 | Лицензия валидна | — |
| 1 | Лицензия не найдена / внутренняя ошибка | `No license key found` |
| 2 | Несоответствие Product ID | `Product ID does not match` |
| 2 | Несоответствие имени продукта | `Product name does not match` |
| 3 | Лицензия истекла | `License is expired` |
| 4 | Подписка истекла | `The Software Maintenance is expired` |
| 5 | Сбой кастомной проверки | `License is OK` (degraded mode) |

### 7.7 API-константы валидации

| Константа | Значение |
|---|---|
| `kerio_jsonapi_admin_LicenseExpired` | Лицензия истекла |
| `kerio_jsonapi_admin_LicenseSoonExpire` | Скоро истекает |
| `kerio_jsonapi_admin_LicenseInvalidDomain` | Неверный домен |
| `kerio_jsonapi_admin_LicenseInvalidEdition` | Неверная редакция |
| `kerio_jsonapi_admin_LicenseInvalidMinVersion` | Версия ниже минимальной |
| `kerio_jsonapi_admin_LicenseInvalidOS` | Неверная ОС |
| `kerio_jsonapi_admin_LicenseInvalidUser` | Неверный пользователь |
| `kerio_jsonapi_admin_LicenseLimit` | Лимит достигнут |
| `kerio_jsonapi_admin_LicenseTooManyUsers` | Слишком много пользователей |
| `kerio_jsonapi_admin_LicenseCheckForwardingEnabled` | Проверка влияет на пересылку |

### 7.8 TinyDB-переменные

| Переменная |
|---|
| `TinydbLicenseVariableId` |
| `TinydbLicenseVariableOS` |
| `TinydbLicenseVariableUsers` |
| `TinydbLicenseVariableCompany` |
| `TinydbLicenseVariableProduct` |
| `TinydbLicenseVariableTrialID` |
| `TinydbLicenseVariableFeatures` |
| `TinydbLicenseVariableLicenseType` |
| `TinydbLicenseVariableLicenseExpires` |
| `TinydbLicenseVariableAntivirusExpires` |
| `TinydbLicenseVariableSubscriptionExpires` |

---

## 8. Исходные файлы

```
/mnt/cache/teamcity/work/Connect92_Engine_EngineLinuxX64release/src/wrmail/registration.cpp
KLicense.cpp
KLicenseInternal.cpp
License.cpp
LicenseDownloader.cpp
AutomaticLicenseUpdate.cpp
AutomaticLicenseUpdater.cpp
TinydbLicenseVariables.cpp
ProductRegistration.cpp
ProductRegistrationImpl.cpp
LicenseManager.cpp
BitDefenderAntispamLicense.cpp
GreylistLicenseMan.cpp
UserLicenseTrackerBase.cpp
UserLicenseTracker.cpp
UserLicenseTrackerMaster.cpp
license_manager.cpp
SaasImpl.cpp
SaasReporter.cpp
alerts.cpp
```

---

## 9. Пример лицензии (Lab Reference)

```
--LICENSE--
Base-ID: 10512-ABL31-8WJ6H
Product: Kerio MailServer
License-Expires: 04 May 2026
Subscription-Expires: 04 May 2026
Users: 25
OS: Linux
Company: HomeLab
E-Mail: foksk76@gmail.com
Features: AV-SOPHOS
Antivirus-Expires: 04 May 2026
Add-On-ID: 10512-ABL31-8WJ6H
--SIGNATURE--
58a99f81384141bd80437db5a5174d9f94a999983c6a3db160632802ee2a4496
df3eb0ca5c59e5ee7be09714f11cdc217d4c2ad4bfa79c3f271efa538c858f05
8f93e65c7a8e4587538e5815af7cdec1df4841e2fd42f05126f1c1cd76071e3d
5a59c8860c125ac2a262df8f6d83c17d1cf75ed993a1706bd06a307444216add
--END--

--PRODUCT-LICENSE--
Base-ID: 10512-ABL31-8WJ6H
Product: Kerio Connect
Product-ID: 1
License-Expires: 04 May 2026
Subscription-Expires: 04 May 2026
Users: 25
OS: Linux
Company: HomeLab
E-Mail: foksk76@gmail.com
License-Type: Trial
License-Version: 2
Format-Version: 1
Feature-Begin: Sophos
License-Expires: 04 May 2026
Subscription-Expires: 04 May 2026
Users: 25
ID: 10512-ABL31-8WJ6H
Feature-End: Sophos
Feature-Begin: ActiveSync
License-Expires: 04 May 2026
Subscription-Expires: 04 May 2026
Users: 25
ID: 10512-ABL31-8WJ6H
Feature-End: ActiveSync
Feature-Begin: Kerio Anti-spam
License-Expires: 04 May 2026
Subscription-Expires: 04 May 2026
Users: 25
ID: 10512-ABL31-8WJ6H
Feature-End: Kerio Anti-spam
--SIGNATURE--
0dd49c235bc5ee475efdccab139fe3c72eb2fa99e8cd2b41cd57a3edba8b6933
f22e14b75fc1dbc4ea4731531f5e16b963a76f9c3730dcc956aa36ddb8213b6e
2f8e3216737550615cbc35e5dd9868c504550ed6f3127b9f9c41c8480dbc8ee4
bfec9a44282d1032ef4ec613c0526e5df82bf8aa961e9a587161c38377df01cf
--PRODUCT-END--
```
