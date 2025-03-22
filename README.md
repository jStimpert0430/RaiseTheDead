# Raise The Dead

Raise The Dead is an Action Platformer for the Pico-8 in which the player must help a recently resurrected skeleton escape from his crypt. Hop on the magic skulls floating throughout the crypt to find the key to each floor's door!

![Raise The Dead](gameplay4.gif)
![Raise The Dead](gameplay2.gif)
![Raise The Dead](gameplay3.gif)

Main project page hosted at -- https://secretbunta.itch.io/raise-the-dead

## Why

The purpose in developing this game was to both to learn how to make pico-8 software and as an attempt to design a game around a single gimmick; In this case, hopping off of enemy heads.

## Controls

* Arrow Keys - Move

* X key - Jump

* Down Key - Fall through the thin wooden floors

* Special Technique - Hold the jump button when hopping off of enemies to jump higher


## Getting Started

open .p8 file in the pico-8 environment and play!

## Built With

* [Pico-8 SDK, lua, Atom] - Environments and language used
	

## Version History

0.1 update notes
* Screenshake added! The code for this had been sitting there unused for a little while, I had to make changes to the camera system implemented to get everything working. Now when you stomp on a skull, the screen will shake
* Fixed fall through wood floors- Previously, unless you kept holding the down arrow, you would be placed back to the top of the wood platform; additionally, if you were holding down when you collided with one you would have just fallen though. Now you will fall though the floor on button press and at least briefly collide with each wooden platform, even if you're holding down.
* Added key gate blocks (trying idea)- Added blocks that block the player for reaching the door unless the player is holding the key. When the player doesn't have they key these blocks are solid and able to be collided against, otherwise the player will fall though them. I like this idea because it gives me an additional gameplay piece to build levels around. Added a few levels in this build around the mechanic; so tell me what you think.
* Re-minimized graphics - Deleted a lot of detail on tileset in an attempt to improve readability of the gameworld. This may change in future updates, but for now I'm pretty happy with it.
* Changed gameplay button to O instead of X based of suggestion - Multiple people suggested I make this switch as it is the pico-8 standard.
* Additional UI tweaks/cleanup/iteration
* Added Gamepad disclaimer
* Added floor 22 and 21

0.0.2 update notes

* Added transition mechanics between death and respawn; Won't respawn instantly not and instead will see a message and a prompt to press the X key.
* Added proper timer control to accommodate aforementioned transition. Timer will now pause on death and restart on respawn correctly.
* Additional small UI tweaks
* Tweaked max jump and fall speed to make the game a little easier to react to.  Additionally, reduced slideyness slightly.
* Further reduced difficulty of hazards in levels in order to smooth difficulty curve
* Added various fluff to levels
* Reworked level 5 and finished building the environment
* Tweaked level 7

0.0.1

* Changed the hazard locations a little bit on the first 3 levels to ease the difficulty a little bit; It should be more enjoyable to get your bearings with the physics now.
	
0.0.0

* initial upload	
	
## Known bugs

* Currently when transitioning from level 4 to level 5; you'll take a death no matter what. This is caused by the code I used to check out of bounds collision; I have to think of a way to tweak it to accommodate how my maps are arranged and how I move from level to level.


## Author

Joshua Stimpert

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details


