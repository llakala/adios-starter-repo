# What is this repo?

This is a little demo setup for using wrappers, using Adios as a module system. Wrappers are an alternative way to
manage dotfiles on a Nix system, instead of something like home-manager - see [this
blogpost](https://fzakaria.com/2025/07/07/home-manager-is-a-false-enlightenment) for some motivation behind them.

Wrappers are pretty simple to set up - you can define them with a basic callPackage set (check out [this
guide](nix.dev/tutorials/callpackage.html) if you're interested in doing that). However, transitioning from
home-manager, I missed the features a module system gave me - the ability to inspect options, typed interfaces, having
one program affect the config of another program, etc. But the NixOS module system has a high overhead, and I wanted to
use something more minimal and lazy. Adios is a very new alternative module system, that I consider to be perfect for
this kind of thing.

# Why is this repo?

I've been supporting some new Adios users (our numbers are growing!), and sending links to my config started being less
helpful. There's a lot there that's hard to understand as a new user, and I wanted to have something to link that only
had the "necessary" stuff.

This repo aims to be very overcommented, so you can understand basic principles of adios modules and how to write
wrappers with them. The main bit of code I actually recommend copying from this repo is the `default.nix` (sans
overexplanatory comments). Understanding how to write Adios modules isn't that hard, but the linking stage of getting
access to those modules is more difficult, and will be the same for pretty much everyone.
