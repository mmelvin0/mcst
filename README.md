# mc-init.sh

This is a tiny shell script to control a Minecraft server.

Intentionally minimalist; it requires only the following basic Unix tools:

- awk
- cat
- egrep
- expr
- fgrep
- head
- id
- printf
- screen
- sh
- sleep
- su (for lowering privileges when run as root)
- tail
- wc

Of course it also requires an appropriate server jar file and Java itself.

The script implements an interface compatible with init scripts. Because of
this you can use it as a drop-in init script for your server, or call it from
a custom script of your own device.

Some configuration is possible by changing the variables at the top of the
script. If present, /etc/default/minecraft is used to fill these in. You can
alternatively configure the tool by exporting as environment variables before
invoking the script.

Run the script without any arguments to see all supported commands.
