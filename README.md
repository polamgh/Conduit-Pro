<div align="center">

🌐 Conduit Manager for macOS

The easiest way to run, monitor, and manage a Psiphon Conduit node on macOS.





Helping people in censored regions access the free internet. 🕊️

English · فارسی

(Note: Interface may vary slightly in newer versions)

</div>

✨ Key Features

Feature

Description

🚀 One-Click Install

No complex terminal commands. Just one line to setup everything.

🖥️ Native Dashboard

Beautiful macOS app to monitor CPU, RAM, and Speed.

🎁 Claim Rewards

Built-in QR Code generator to claim your node rewards in Ryve.

🛡️ Security Hardened

Runs in an isolated Docker container with read-only filesystem.

🔄 Auto Update

Keep your node up-to-date with a single click.

🆔 Identity Backup

Easily Backup & Restore your node_key to keep your reputation.

🚀 Quick Start

1. Prerequisites

You must have Docker Desktop installed and running.

Download Docker Desktop for Mac

2. Installation Options

Option A: Automatic Install (Recommended)

Open your Terminal app and paste this command. It automatically downloads, installs, and fixes permissions:

curl -fsSL [https://raw.githubusercontent.com/polamgh/conduit-manager-mac/main/install.sh](https://raw.githubusercontent.com/polamgh/conduit-manager-mac/main/install.sh) | bash


Option B: Manual Download

If you prefer to download the file yourself:

Go to the Releases Page.

Download Conduit.zip (or Conduit Pro.zip).

Unzip and move the app to your Applications folder.

Note: You might need to right-click and select "Open" to bypass security warnings.

3. Usage

Open Conduit from your Applications folder.

Set your Max Clients (e.g., 200) and Bandwidth.

Click Start Service.

Wait for the status to turn Running & Healthy.

Note: It may take 1 to 24 hours for the Psiphon network to discover your node and for users to connect. Please be patient if you see "0 Users" initially.

🎁 How to Claim Rewards

Open the app and ensure the service is Running.

Click the Claim Rewards button (or QR icon).

Scan the generated QR Code using the Ryve App.

Your node is now linked to your wallet!

<div dir="rtl" align="right">

🍎 راهنمای نصب فارسی

مدیریت آسان نودهای Conduit روی مک‌بوک
بدون نیاز به دانش فنی، نود خود را راه‌اندازی کنید و به اینترنت آزاد کمک کنید.

✨ ویژگی‌ها

نصب آسان: تنها با یک خط دستور یا دانلود مستقیم.

داشبورد گرافیکی: مشاهده سرعت لحظه‌ای، تعداد کاربران و مصرف منابع.

دریافت پاداش: تولید خودکار کد QR برای اپلیکیشن Ryve.

امنیت بالا: اجرا در محیط ایزوله داکر.

📥 روش‌های نصب

۱. پیش‌نیاز:
ابتدا برنامه Docker Desktop را روی مک خود نصب و اجرا کنید.

۲. نصب (دو روش):

روش اول: نصب خودکار (پیشنهادی)
ترمینال را باز کنید و دستور زیر را اجرا کنید (این روش تمام مجوزها را خودکار تنظیم می‌کند):

curl -fsSL [https://raw.githubusercontent.com/polamgh/conduit-manager-mac/main/install.sh](https://raw.githubusercontent.com/polamgh/conduit-manager-mac/main/install.sh) | bash


روش دوم: دانلود دستی

به صفحه Releases بروید.

فایل فشرده (.zip) را دانلود کنید.

برنامه را در پوشه Applications کپی کنید.

نکته: اگر موقع باز کردن خطا داد، روی برنامه کلیک راست کنید و Open را بزنید.

۳. اجرا:

تنظیمات دلخواه (تعداد کاربر و پهنای باند) را وارد کنید.

دکمه Start Service را بزنید.

⚠️ نکته مهم: پس از روشن کردن سرور، ممکن است بین ۱ تا ۲۴ ساعت طول بکشد تا شبکه نود شما را شناسایی کند و کاربران متصل شوند. لطفاً صبور باشید.

</div>

🛠 Troubleshooting

Docker not found?
Ensure Docker Desktop is running. The app will prompt you to open it if it's closed.

Permission Denied?
The app automatically fixes permissions. If you built it from source, remove App Sandbox in Xcode.

No Users Connecting?
Check if your internet allows UDP traffic. Using a personal hotspot or changing ISPs might help. Also, give it up to 24 hours.

📄 License

This project is open-source and licensed under the MIT License.

<div align="center">
<sub>Built with ❤️ for #FreeIran</sub>
</div>