## Jack of All Things

**Current Version**: ~dev_version~ \
**Updated**: ~date~

* Adds an action tab to items and spells. Allows for editing spell effects without putting the record onto a character.
* Adds the ability to set actions to items, which will be shown on the character's Action Tab when the item is equipped.
* Adds charges to items. Automated recharging.  Can have items recharged using a die.  Can configure something to happen when the item runs out of charges.
* Adds inventories to NPCs. The primary benefit of this feature at present is to give NPCs items that have Actions.
* Time-based recharge. When used in conjunction with the Clock Adjuster extension, items may be configured to recharge daily at Dawn, Noon, Dusk, or Midnight.
* Equipped Effects. When the two extensions are used in conjunction, the power automation feature of Equipped Effects will add the power to the item.
* Automatic Effects data. Leverages data in Automatic effects to automate item recharge configuration for items equipped while using Equipped Effects and Clock Adjuster.
* Targeting Window. Huge icons. Option to open automatically on turn defaulted to off. Otherwise open by double-clicking target icon within CT targetting tab.
* Collapse all and expand all buttons on PC actions tab. Adds collapsibility to Spell Slots and Generic Actions headings.

### Other Extensions

Care has been taken to avoid negative interactions with other extensions.  Current extension support includes:
* Equipped Items, Advanced Effects, Map Parcels, Clock Adjuster, Combat Automation, 5e Automatic Effects, Generic Actions.

If you find any negative interactions with other extensions, please let the maintainer know on the forums or Discord.

### Installation

It is recommended that you disable and hide Kit'N'Kaboodle on your Forge account.  And if you have downloaded any releases from github, you should also delete any copies of KitNKaboodle.ext in your extensions folder. \
Install from the [Fantasy Grounds Forge](https://forge.fantasygrounds.com/shop/items/1959/view). \
You can find the source code at Farratto's [GitHub](https://github.com/Farratto/JackOfAllThings/releases). \
You can ask questions at the [Fantasy Grounds Forum](https://www.fantasygrounds.com/forums/showthread.php?83081-Jack-of-All-Trades-for-5e-(rebranding-of-Kit-N-Kaboodle)) thread.

### Attribution

Jack of All Things is a rebranding of Kit'N'Kaboodle by MeAndUnique.  M&U no longer supports KNK.  Farratto is the maintainer of Jack of All Trades.

SmiteWorks owns rights to code sections copied from their rulesets by permission for Fantasy Grounds community development. \
'Fantasy Grounds' is a trademark of SmiteWorks USA, LLC. \
'Fantasy Grounds' is Copyright 2004-2021 SmiteWorks USA LLC.

Icons made by [Freepik](https://www.freepik.com) from [www.flaticon.com](https://www.flaticon.com/). \
Icons made by [pongsakornRed](https://www.flaticon.com/authors/pongsakornred) from [www.flaticon.com](https://www.flaticon.com/) \
Icons made by [sbed](https://opengameart.org/users/sbed) and [Delapouite](https://delapouite.com/) from [Game-icons.net](https://game-icons.net/)

### Change Log

* v3.5.3: FIXED: nil error when destroying item
* v3.5.2: FIXED: Switching from JoAT items to Equipped Effects required restart to take effect. Expand/Collapse all buttons added to Floating tabs.
* v3.5.1: FIXED: ineractions with Winnowing Pursuits. slight aesthetic improvements.
* v3.5.0: Expand/Collapse all buttons added to Actions tab. Actions added by JoAT are now placed above Generic Actions.
* v3.4.2: Negative interaction with Legendary Assistant. FIXED
* v3.4.1: Negative interaction with Arcane Ward ext. FIXED
* v3.4.0: Added option to keep targeting window open on turn change
* v3.3.4: Disabled inventory tab on NPCs. This is functionality is covered by Map Parcels extension.
* v3.3.3: Spamming console log: FIXED.
* v3.3.2: Was sending NPC pictures to all connected clients. FIXED
* v3.3.1: Fixed interaction with Spell Action Info
* v3.3.0: New Option: Players may double-click nonfriendly NPCs to see their highres picture
* v3.2.0: Added Next Actor button to targetting window.
* v3.1.6: New targetting window with huge icons. Option to auto-open defaulted to off.
* v3.1.4: Updated UI Elements in support of next round of deprecations. Minor Aesthetic Improvement.
* v3.1.3: Previous patch not functioning as intended: Fixed.
* v3.1.2: You may now close the offense tab in CT for current actor.
* v3.1.1: Added warning window if loading both KNK and JoAT
* v3.1.0: Rebranded to Jack of All Things. Minor bug fixes to accomdate Combat Automation extension.