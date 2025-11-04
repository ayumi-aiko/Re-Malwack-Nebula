![tsu](https://github.com/ayumi-aiko/banners/blob/main/explore00.png?raw=true)

# What's new on v6.0 from Nebula? ✨
- Switched to the new extended module template and added hoshiko-cli into the builds and the module.
- Updated binaries to the commit [0196323a03e07bc2c8e8093a2f3e49f2a056da6f](https://github.com/bocchi-the-dev/Hoshiko/commit/0196323a03e07bc2c8e8093a2f3e49f2a056da6f) from [Hoshiko](https://github.com/bocchi-the-dev/Hoshiko)
- Fixed the human-error where the `"customize.sh"` skips to extract the `"service.sh"` due to a variable being set to `false` instead of `true`.
- Changed the banner art because it was pointing to a older codename of the Hoshiko project.
- Fixed invalid path for sourcing `properties.prop`, Thanks to [@ZG089](https://github.com/ZG089) for pointing it out.
- Added a prompt in the builder script for building Hoshiko and now it can be built and used throughout multiple android versions while maintaining least possible stability on older android versions.

## Notes
- Please install this module on a Android device that has at least Android 6 or above.
- This module contains some modifications that are not mostly present in the [ZG089's Malwack Fork, known as Re-Malwack](https://github.com/ZG089/Re-Malwack/).

Thank you!