# Irc bot written in coffeescript #

## setup instructions ##

1. install node.js and npm
2.  clone the repo
3.  on the commandline

> npm install
>
> ./bin/setup
>
> edit data/settings.json and fill in the settings

## to run ##
> ./bin/bot

## modules ##
modules sit inside the modules directory
check the Readme there to create new modules

## limitations ##
Currently the bot assumes that you only want to sit in one channel. This assumption
is baked into a lot of the core functionality and modules.

## todo ##

move count to a different model


other dependencies by now
libicu-dev
libexpat1-dev
