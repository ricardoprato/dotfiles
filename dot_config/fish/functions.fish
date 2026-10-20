# Crear un nuevo directorio y entrar en él
# function mkd
#     mkdir -p $argv; and cd $argv
# end
#
# # Función para mostrar el uso del disco
# function fs
#     if test (du -b /dev/null > /dev/null 2>&1); 
#         set arg -sbh; 
#     else 
#         set arg -sh; 
#     end
#
#     if test (count $argv) -gt 0; 
#         du $arg -- $argv; 
#     else 
#         du $arg .[^.]* ./*; 
#     end
# end
#
# # Manejar comandos no encontrados
# function command_not_found_handler
#     set purple (set_color purple)
#     set bright (set_color bold)
#     set green (set_color green)
#     set reset (set_color normal)
#
#     printf 'fish: command not found: %s\n' "$argv[1]"
#
#     set entries (command pacman -F --machinereadable -- "/usr/bin/$argv[1]")
#
#     if test (count $entries) -gt 0
#         printf "${bright}$argv[1]${reset} puede encontrarse en los siguientes paquetes:\n"
#         set pkg ""
#
#         for entry in $entries
#             set fields (string split / $entry)
#             if test "$pkg" != "$fields[2]"
#                 printf "${purple}%s/${bright}%s ${green}%s${reset}\n" "$fields[1]" "$fields[2]" "$fields[3]"
#             end
#             printf '    /%s\n' "$fields[4]"
#             set pkg "$fields[2]"
#         end
#     end
#
#     return 127
# end
#
# # Detectar el envoltorio AUR
# if command pacman -Qi yay > /dev/null 2>&1
#     set aurhelper "yay"
# else if command pacman -Qi paru > /dev/null 2>&1
#     set aurhelper "paru"
# end
#

# Función kt para seleccionar un directorio y abrirlo en una nueva pestaña de kitty
