# Charging Tracker

A Flutter app for logging EV charging sessions and keeping a balance of fast and
slow charges. Data stays on the device in a local SQLite database.

A cycle is a run of fast charges closed by a slow charge. The target is four fast
charges, then one slow.

## Backups

Use the menu on the Dashboard to export or import a JSON backup. Importing only
adds sessions that are missing, so it never changes or removes existing ones.

## Release signing

Release builds use `android/key.properties` when it exists and the debug key
otherwise:

```properties
storeFile=/absolute/path/to/release.jks
storePassword=...
keyAlias=...
keyPassword=...
```

Android will not update an app signed with a different key, and uninstalling it
erases its database. Export a backup before changing the key on a device that
already has data, then import it after reinstalling.
