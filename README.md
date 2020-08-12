
<h1 align="center">
  <img src="https://github.com/jerichoi224/MoneyTracker/blob/master/media/cover.png">
</h1>

Application for Tracking Daily Money Usage in hope of helping me save money, made with Flutter.
[Available in Google Play Store](https://play.google.com/store/apps/details?id=com.kahluabear.money_tracker)

### Development Status
I've added everything I wanted to add for my personal need which includes the functions and support for Dollars and Korean Won. If requested, I can add more currency, but unless I come up with more ideas on functionalities or find bugs while using it, the development will be on pause for now. 

## Basic Overview
The Basic Idea is that you are able to decide how much you want to be using every day on average, and the app will let you keep track of how much you've spent/saved daily and overall.

### Basic Functionality
<img src="https://github.com/jerichoi224/MoneyTracker/blob/master/media/screenshots1.jpeg">

The three screenshots above show the basic functionality of the app. You Record your spendings, on the left. You can see how much you have left today and how much you've saved so far in the middle and see all your previous spendings on the right. For the Display portion, "Remaining Today" will show the value of the daily limit subtracted by the amount you've spent today. At midnight, whatever is remaining from the day will get added to the "Total Savings."


### More Functionalities
<img src="https://github.com/jerichoi224/MoneyTracker/blob/master/media/screenshots2.jpeg">

The app includes a Splash screen as well as a one-time intro screen that gives you a brief explanation and also lets you set the daily limit before actually starting the app.

The Setting Menu lets you change the daily limit, the system UI, and manage subscriptions. You can add a "Save" button along with the Spend button if you want to add money to your savings. This is disabled by default as my idea of this app was simply recording my spendings regardless of how much money I have, so that I don't go easy on myself when I earn money. Changing to show the entire history will show all spendings in a infinitely growing list instead of showing it day by day.

The Subscription Management lets you register subscription payments for monthly or yearly payments. On the day of payment, a spending entry will be automatically created.

### Open Source!

This app, while it was built for my own use, I ended up learning alot on how to build apps using Flutter, or at least alot of the basic functionalities (no fancy libraries or APIs or network use). And I think this would give help on people learning Flutter. I use alot of the basic functionalities that are crucial in many apps including, but not limited to saving/loading data to shared preferences and database, using splash screens, scroll view layout, non-scroll view navigation, etc. Hopefully this is useful for whoever ends up here!
