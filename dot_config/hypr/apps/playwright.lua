-- Chrome lanzado por el MCP de Playwright (validaciones de UI hechas por la IA).
-- La class la fuerza ~/.config/playwright-mcp.json con --class=playwright-mcp,
-- para no pisar reglas del Chrome de uso normal (class "google-chrome").
--
-- Por que: cada accion del MCP hace que Chrome pida activacion via
-- xdg-activation-v1; con misc:focus_on_activate = true (looknfeel.lua)
-- Hyprland obedece y salta a la ventana.

-- 1. Ignorar los pedidos de activacion durante la automatizacion.
o.window("playwright-mcp", { focus_on_activate = false })

-- 2. No tomar el foco al abrirse.
o.window("playwright-mcp", { no_initial_focus = true })

-- 3. Nace en un workspace especial oculto: no aparece nunca encima de lo que
--    estas haciendo. Para mirar la automatizacion en vivo:
--      hyprctl dispatch togglespecialworkspace playwright
o.window("playwright-mcp", { workspace = "special:playwright silent" })
