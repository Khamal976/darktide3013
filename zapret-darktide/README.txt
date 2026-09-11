Darktide 3013 + zapret  (сборка Flowseal/zapret-discord-youtube 1.9 и новее)
==========================================================================

Установка:
  1. Скопируйте darktide-setup.bat и darktide-setup.ps1 в папку zapret, рядом с general.bat.
  2. Запустите darktide-setup.bat (обычным двойным щелчком). Он:
       - добавит домены игры в lists\list-general-user.txt;
       - создаст darktide.bat, darktide (ALT).bat, darktide (ALT2).bat ... по одному
         на каждую стратегию general*.bat, которая есть в папке.
  3. Запустите darktide.bat от имени администратора. Окно не закрывать. Запустите игру.
  4. Если 3013 остался, закройте окно и попробуйте darktide (ALT).bat, ALT2, ALT3 ...
     Стратегия подбирается под провайдера так же, как для YouTube и Discord:
     если у вас работает general (ALT11).bat, берите darktide (ALT11).bat.

Что внутри darktide*.bat по сравнению с general*.bat:
  - порты 35000-36000 (хаб- и игровые серверы Darktide) добавлены в перехват UDP;
  - первым профилем идёт fake-STUN для UDP на эти порты: перед реальным пакетом игры
    zapret отправляет поддельный STUN-запрос, и DPI считает поток «звонком», а не
    неизвестным UDP до заблокированного хостинга;
  - в профиле Game Filter (если есть) ACTIVE_GAME_UDP.bin заменён на stun.bin.
    Это находка сообщества (Steam, тема 565912359496984390): на 11.09.2026 фейк
    ACTIVE_GAME_UDP перестал проходить, а STUN проходит.
  - домены авторизации atoma.cloud и atoma-discovery.com обрабатываются общей TLS-стратегией
    через list-general-user.txt.

Ничего другого в вашей папке zapret не меняется. Удалить: сотрите darktide*.bat и две
строки из lists\list-general-user.txt.

Подробный разбор ошибки: https://khamal976.github.io/darktide3013/
