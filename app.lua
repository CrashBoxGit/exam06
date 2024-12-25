lgi = require 'lgi'

gtk = lgi.Gtk
gio = lgi.Gio
GLib = lgi.GLib

gtk.init()

bld = gtk.Builder()
bld:add_from_file('lab07-mykhailiv.glade')

local ui = bld.objects

-- Проверим, что все элементы загружены
print("Загруженные элементы из .glade:")
for name, obj in pairs(ui) do
    print(name, obj)
end

-- Инициализируем метки
local total_memory_label = ui.total_memory
local free_memory_label = ui.free_memory
local available_memory_label = ui.available_memory

local pid_label = ui.pid1
local name_label = ui.name1
local cpu_usage_label = ui.cpu_usage1
local memory_usage_label = ui.memory_usage1

local interface_name_label = ui.interface_name
local bytes_received_label = ui.bytes_received
local bytes_sent_label = ui.bytes_sent

-- Функция для обновления информации о памяти
local function update_memory_info()
    local file = io.open('/proc/meminfo', 'r')
    if file then
        local total_memory, free_memory, available_memory
        for line in file:lines() do
            if line:match("MemTotal") then
                total_memory = tonumber(line:match(":%s+(%d+)"))
            elseif line:match("MemFree") then
                free_memory = tonumber(line:match(":%s+(%d+)"))
            elseif line:match("MemAvailable") then
                available_memory = tonumber(line:match(":%s+(%d+)"))
            end
        end
        file:close()

        if total_memory_label then
            total_memory_label:set_text(total_memory and total_memory .. " kB" or "N/A")
        end
        if free_memory_label then
            free_memory_label:set_text(free_memory and free_memory .. " kB" or "N/A")
        end
        if available_memory_label then
            available_memory_label:set_text(available_memory and available_memory .. " kB" or "N/A")
        end
    end
end

-- Функция для обновления информации о процессе
local function update_process_info()
    local handle = io.popen("ps -eo pid,comm,%cpu,%mem --sort=-%mem | head -n 2") -- Один процесс (заголовок + 1 строка)
    local processes_info = handle:read("*all")
    handle:close()

    local lines = {}
    for line in processes_info:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    local pid, name, cpu_usage, memory_usage = lines[2]:match("^(%S+)%s+(%S+)%s+(%S+)%s+(%S+)")
    if pid_label and pid then
        pid_label:set_text(pid)
    end
    if name_label and name then
        name_label:set_text(name)
    end
    if cpu_usage_label and cpu_usage then
        cpu_usage_label:set_text(cpu_usage .. " %")
    end
    if memory_usage_label and memory_usage then
        memory_usage_label:set_text(memory_usage .. " %")
    end
end

-- Функция для обновления информации о сети
local function update_network_info()
    local net_dir = "/sys/class/net/"
    local dir = io.popen("ls " .. net_dir)
    local interfaces = dir:read("*all")
    dir:close()

    for interface in interfaces:gmatch("[^\r\n]+") do
        local rx_file = io.open(net_dir .. interface .. "/statistics/rx_bytes", "r")
        local tx_file = io.open(net_dir .. interface .. "/statistics/tx_bytes", "r")

        local bytes_received = rx_file and rx_file:read("*all") or "N/A"
        local bytes_sent = tx_file and tx_file:read("*all") or "N/A"

        if rx_file then rx_file:close() end
        if tx_file then tx_file:close() end

        if interface_name_label then
            interface_name_label:set_text(interface)
        end
        if bytes_received_label then
            bytes_received_label:set_text(bytes_received)
        end
        if bytes_sent_label then
            bytes_sent_label:set_text(bytes_sent)
        end

        -- Обрабатываем только первый интерфейс для теста
        break
    end
end

-- Обновление всех данных каждые 5 секунд
local function update_all()
    update_memory_info()
    update_process_info()
    update_network_info()
end

-- Устанавливаем таймер для обновлений
GLib.timeout_add(GLib.PRIORITY_DEFAULT, 5000, function()
    update_all()
    return true -- Продолжаем таймер
end)

-- Обновление данных при запуске
update_all()

-- Обработчик закрытия окна
function ui_destroy()
    gtk.main_quit()
end

ui.wnd:show_all()
gtk.main()

