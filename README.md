# mc-init.sh

This is a tiny shell script to control a Minecraft server.

Intentionally minimalist; it requires only the following basic Unix tools:

- awk
- cat
- egrep
- expr
- fgrep
- head
- printf
- screen
- sh
- tail
- wc

Of course it also requires an appropriate server jar file and Java itself.

The script implements an interface compatible with init scripts. Because of
this you can use it as a drop-in init script for your server, or call it from
a custom script of your own device.

Some configuration is possible by changing the variables at the top of the
script. You can also configure the tool by exporting these as environment
variables before calling the mc-init.sh.

Run the script without any arguments to see all supported commands.
