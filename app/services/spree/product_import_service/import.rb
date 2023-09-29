module Spree
    class ProductImportService::Import

        def initialize(file)
            puts "ProductImportService::Import initialize"
            @file = file
            @header
            @file_data = []
            @import_data
        end 
        
        def collect_data
            puts 'импорт файла '+Time.now.to_s

            spreadsheet = open_spreadsheet(@file)
            header = spreadsheet.row(1)
            @header = header
            (2..spreadsheet.last_row).each do |i|
                row = Hash[[header, spreadsheet.row(i)].transpose]
                @file_data.push(row)
            end
            # puts 'header => '+@header.to_s
            # puts 'incase_data => '+@incase_data.to_s
            puts 'конец импорт файл '+Time.now.to_s
            @import_data = @header.present? && @file_data.present? ? {header: @header, file_data: @file_data} : false
        end

        def self.convert_file_data(data)
            update_rules = data[:update_rules]
            lines = data[:lines]
            # puts "lines => "+lines.to_s
            n_lines = Array.new
            lines.each do |line|
                n_l = Hash.new
                line.each do |k,v|
                    #search_system_key_name = update_rules[0].key(k)
                    search_system_key_name = update_rules[0].select{|u_k,u_v| u_k if u_v == k }
                    # puts "search_system_key_name => "+search_system_key_name.to_s
                    if search_system_key_name.present?
                        new_key = search_system_key_name.keys[0]
                        # puts "new_key is a string? => "+new_key.respond_to?(:to_str).to_s
                        n_l[new_key] = v
                    else
                        n_l[k] = v
                    end
                end
                n_lines.push(n_l)
            end
            puts "convert_file_data n_lines present? => "+n_lines.present?.to_s
            #n_lines
            data_group_by_unumber = n_lines.group_by { |d| d["unumber"] }
        end

        def self.collect_virtual_incases(data_group_by_unumber)
            incases = Array.new
            incase_attributes = Incase.attribute_names
            #data_group_by_unumber.each_with_index do |(k,v), index|
            data_group_by_unumber.values.each_with_index do |v, index|
                virtual_incase = Hash.new
                lines = Array.new
                v.each do |line|
                    # puts "line => "+line.to_s
                    incase_attributes.each do |i_a|
                        value = []
                        line.each do |k,v|
                            value.push(v) if k == i_a
                        end
                        virtual_incase[i_a] = value.reject(&:blank?).uniq.join if value.present?
                    end

                    incase_attributes.each do |i_a|
                    line.delete(i_a)
                    end
                    lines.push(line)
                    end
                    virtual_incase["lines"] = lines
                    incases.push(virtual_incase)
                end
            puts "collect_virtual_incases virtual_incases count => "+incases.count.to_s
            incases
        end

        def self.update(data)
        
        end

        def open_spreadsheet(file)
            case File.extname(file.original_filename)
            when ".csv" then Roo::CSV.new(file.path)#, csv_options: {col_sep: "\t",encoding: "windows-1251:utf-8"})
            when ".xls" then Roo::Excel.new(file.path)
            when ".xlsx" then Roo::Excelx.new(file.path)
            when ".XLS" then Roo::Excel.new(file.path)
            else raise "Unknown file type: #{file.original_filename}"
            end
        end
        
        def self.test_lines
            [   {"region"=>"МСК", "strah"=>"Альфа", "unumber"=>"0191/046/00098/23", "stoanumber"=>"ЗН-0167347", "company"=>"ЛУКАВТО (ЛУКОЙЛ-Центрнефтепродукт)", "Марка ТС"=>"MERCEDES-BENZ", "Модель ТС"=>"S450", "carnumber"=>"А377АА777", "detal title"=>"БАМПЕР ПЕРЕДНИЙ", "date"=>"2023-06-02", "sum"=>"", "totalsum"=>"281371.49", "katnumber"=>"A22288095009999"}, 
            {"region"=>"МСК", "strah"=>"Альфа", "unumber"=>"0191/046/00098/23", "stoanumber"=>"ЗН-0167347", "company"=>"ЛУКАВТО (ЛУКОЙЛ-Центрнефтепродукт)", "Марка ТС"=>"MERCEDES-BENZ", "Модель ТС"=>"S450", "carnumber"=>"А377АА777", "detal title"=>"РЕШЕТКА ПЕРЕДНЕГО БАМПЕРА", "date"=>"2023-06-02", "sum"=>"", "totalsum"=>"", "katnumber"=>"A2228857100"}, 
            {"region"=>"МСК", "strah"=>"Альфа", "unumber"=>"0191/046/00098/23", "stoanumber"=>"ЗН-0167347", "company"=>"ЛУКАВТО (ЛУКОЙЛ-Центрнефтепродукт)", "Марка ТС"=>"MERCEDES-BENZ", "Модель ТС"=>"S450", "carnumber"=>"А377АА777", "detal title"=>"МОЛДИНГ ПЕРЕДНЕГО БАМПЕРА", "date"=>"2023-06-02", "sum"=>"", "totalsum"=>"", "katnumber"=>"A2228857600"}, 
            {"region"=>"МСК", "strah"=>"Альфа", "unumber"=>"0191/046/00098/23", "stoanumber"=>"ЗН-0167347", "company"=>"ЛУКАВТО (ЛУКОЙЛ-Центрнефтепродукт)", "Марка ТС"=>"MERCEDES-BENZ", "Модель ТС"=>"S450", "carnumber"=>"А377АА777", "detal title"=>"НАКЛАДКА БАМПЕРА ЛЕВАЯ", "date"=>"2023-06-02", "sum"=>"", "totalsum"=>"", "katnumber"=>"A2228857700"}, 
            {"region"=>"МСК", "strah"=>"Альфа", "unumber"=>"0191/046/00098/23", "stoanumber"=>"ЗН-0167347", "company"=>"ЛУКАВТО (ЛУКОЙЛ-Центрнефтепродукт)", "Марка ТС"=>"MERCEDES-BENZ", "Модель ТС"=>"S450", "carnumber"=>"А377АА777", "detal title"=>"НАКЛАДКА БАМПЕРА ПРАВАЯ", "date"=>"2023-06-02", "sum"=>"", "totalsum"=>"", "katnumber"=>"A2228857800"}, 
            {"region"=>"МСК", "strah"=>"Альфа", "unumber"=>"0194/046/00170/23", "stoanumber"=>"023-0995", "company"=>"Тушино сервис", "Марка ТС"=>"LEXUS", "Модель ТС"=>"ES", "carnumber"=>"К029СХ777", "detal title"=>"БАМПЕР ПЕРЕДНИЙ", "date"=>"2023-06-02", "sum"=>"", "totalsum"=>"353408.0", "katnumber"=>"521193T910"}, 
            {"region"=>"МСК", "strah"=>"Альфа", "unumber"=>"0194/046/00170/23", "stoanumber"=>"023-0995", "company"=>"Тушино сервис", "Марка ТС"=>"LEXUS", "Модель ТС"=>"ES", "carnumber"=>"К029СХ777", "detal title"=>"НАКЛАДКА ПРОТИВОТУМАННОЙ ФАРЫ", "date"=>"2023-06-02", "sum"=>"", "totalsum"=>"", "katnumber"=>"8148233070"}, {"region"=>"МСК", "strah"=>"Альфа", "unumber"=>"0194/046/00170/23", "stoanumber"=>"023-0995", "company"=>"Тушино сервис", "Марка ТС"=>"LEXUS", "Модель ТС"=>"ES", "carnumber"=>"К029СХ777", "detal title"=>"НАПРАВЛЯЮЩАЯ БАМПЕРА ПЕР ЛЕВАЯ", "date"=>"2023-06-02", "sum"=>"", "totalsum"=>"", "katnumber"=>"5214633070"}, {"region"=>"МСК", "strah"=>"Альфа", "unumber"=>"0194/046/00170/23", "stoanumber"=>"023-0995", "company"=>"Тушино сервис", "Марка ТС"=>"LEXUS", "Модель ТС"=>"ES", "carnumber"=>"К029СХ777", "detal title"=>"НАПОЛНИТЕЛЬ БАМПЕРА ПЕРЕДНЕГО", "date"=>"2023-06-02", "sum"=>"", "totalsum"=>"", "katnumber"=>"5261133280"}, {"region"=>"МСК", "strah"=>"Альфа", "unumber"=>"0194/046/00170/23", "stoanumber"=>"023-0995", "company"=>"Тушино сервис", "Марка ТС"=>"LEXUS", "Модель ТС"=>"ES", "carnumber"=>"К029СХ777", "detal title"=>"МОЛДИНГ РЕШЕТКИ РАДИАТОРА", "date"=>"2023-06-02", "sum"=>"", "totalsum"=>"", "katnumber"=>"5312133090"}, {"region"=>"МСК", "strah"=>"АО СК ПАРИ", "unumber"=>"009-23.01223716", "stoanumber"=>"023-0999", "company"=>"Тушино сервис", "Марка ТС"=>"LADA", "Модель ТС"=>"LARGUS", "carnumber"=>"Н631АК799", "detal title"=>"МОЛДИНГ ПЕРЕДНЕЙ ДВЕРИ ЛЕВЫЙ", "date"=>"2023-06-02", "sum"=>"", "totalsum"=>"23854.84", "katnumber"=>"8450000409"}, {"region"=>"МСК", "strah"=>"АО СК ПАРИ", "unumber"=>"009-23.01223716", "stoanumber"=>"023-0999", "company"=>"Тушино сервис", "Марка ТС"=>"LADA", "Модель ТС"=>"LARGUS", "carnumber"=>"Н631АК799", "detal title"=>"ФАРТУК ПЕР КРЫЛА ЛЕВ", "date"=>"2023-06-02", "sum"=>"", "totalsum"=>"", "katnumber"=>"8450000980"}, {"region"=>"МСК", "strah"=>"АО СК ПАРИ", "unumber"=>"009-23.01223716", "stoanumber"=>"023-0999", "company"=>"Тушино сервис", "Марка ТС"=>"LADA", "Модель ТС"=>"LARGUS", "carnumber"=>"Н631АК799", "detal title"=>"МОЛДИНГ АРКИ КРЫЛА ПЕРЕДНИЙ ЛЕВ", "date"=>"2023-06-02", "sum"=>"", "totalsum"=>"", "katnumber"=>"6001548285"}, {"region"=>"МСК", "strah"=>"СОГАЗ", "unumber"=>"23MT0674D№0000001", "stoanumber"=>"ШМТ0000344", "company"=>"Шмит-Моторс", "Марка ТС"=>"TOYOTA", "Модель ТС"=>"FORTUNER", "carnumber"=>"Н081ВУ799", "detal title"=>"БАМПЕР ЗАДНИЙ", "date"=>"2023-06-02", "sum"=>"", "totalsum"=>"220100.4", "katnumber"=>"521590K950"}, {"region"=>"МСК", "strah"=>"СОГАЗ", "unumber"=>"23MT0674D№0000001", "stoanumber"=>"ШМТ0000344", "company"=>"Шмит-Моторс", "Марка ТС"=>"TOYOTA", "Модель ТС"=>"FORTUNER", "carnumber"=>"Н081ВУ799", "detal title"=>"ГЛУШИТЕЛЬ ЗАДНЯЯ ЧАСТЬ", "date"=>"2023-06-02", "sum"=>"", "totalsum"=>"", "katnumber"=>"174050L220"}, {"region"=>"МСК", "strah"=>"СОГАЗ", "unumber"=>"23MT0674D№0000001", "stoanumber"=>"ШМТ0000344", "company"=>"Шмит-Моторс", "Марка ТС"=>"TOYOTA", "Модель ТС"=>"FORTUNER", "carnumber"=>"Н081ВУ799", "detal title"=>"КРЫШКА БАГАЖНИКА", "date"=>"2023-06-02", "sum"=>"", "totalsum"=>"", "katnumber"=>"67005KK140"}, {"region"=>"МСК", "strah"=>"СОГАЗ", "unumber"=>"23MT0674D№0000001", "stoanumber"=>"ШМТ0000344", "company"=>"Шмит-Моторс", "Марка ТС"=>"TOYOTA", "Модель ТС"=>"FORTUNER", "carnumber"=>"Н081ВУ799", "detal title"=>"ПЕТЛЯ БУКСИР ЗАДНЯЯ", "date"=>"2023-06-02", "sum"=>"", "totalsum"=>"", "katnumber"=>"510950K010"}, {"region"=>"МСК", "strah"=>"СОГАЗ", "unumber"=>"23MT0674D№0000001", "stoanumber"=>"ШМТ0000344", "company"=>"Шмит-Моторс", "Марка ТС"=>"TOYOTA", "Модель ТС"=>"FORTUNER", "carnumber"=>"Н081ВУ799", "detal title"=>"ПЫЛЬНИК ЗАДНЕГО БАМПЕРА ПРАВЫЙ", "date"=>"2023-06-02", "sum"=>"", "totalsum"=>"", "katnumber"=>"662510K020"}, {"region"=>"МСК", "strah"=>"СОГАЗ", "unumber"=>"23MT0674D№0000001", "stoanumber"=>"ШМТ0000344", "company"=>"Шмит-Моторс", "Марка ТС"=>"TOYOTA", "Модель ТС"=>"FORTUNER", "carnumber"=>"Н081ВУ799", "detal title"=>"РАСШИРИТЕЛЬ ЗАДНИЙ ПРАВЫЙ", "date"=>"2023-06-02", "sum"=>"", "totalsum"=>"", "katnumber"=>"527060K010"}, {"region"=>"МСК", "strah"=>"СОГАЗ", "unumber"=>"23MT0674D№0000001", "stoanumber"=>"ШМТ0000344", "company"=>"Шмит-Моторс", "Марка ТС"=>"TOYOTA", "Модель ТС"=>"FORTUNER", "carnumber"=>"Н081ВУ799", "detal title"=>"СПОЙЛЕР ЗАДНЕГО БАМПЕРА НИЖН Ч", "date"=>"2023-06-02", "sum"=>"", "totalsum"=>"", "katnumber"=>"521690K170"}, {"region"=>"МСК", "strah"=>"СОГАЗ", "unumber"=>"23MT0674D№0000001", "stoanumber"=>"ШМТ0000344", "company"=>"Шмит-Моторс", "Марка ТС"=>"TOYOTA", "Модель ТС"=>"FORTUNER", "carnumber"=>"Н081ВУ799", "detal title"=>"УСИЛИТЕЛЬ ЗАДНЕГО БАМПЕРА", "date"=>"2023-06-02", "sum"=>"", "totalsum"=>"", "katnumber"=>"523460K020"}]
        end

        def self.test_one_incase
            [   
                {"region"=>"МСК", "strah_id"=>"Альфа", "unumber"=>"0191/046/00098/23", "stoanumber"=>"ЗН-0167347", "company_id"=>"ЛУКАВТО (ЛУКОЙЛ-Центрнефтепродукт)", "Марка ТС"=>"MERCEDES-BENZ", "Модель ТС"=>"S450", "carnumber"=>"А377АА777", "detal title"=>"БАМПЕР ПЕРЕДНИЙ", "date"=>"2023-06-02", "sum"=>"", "totalsum"=>"281371.49", "katnumber"=>"A22288095009999"}, 
                {"region"=>"МСК", "strah_id"=>"Альфа", "unumber"=>"0191/046/00098/23", "stoanumber"=>"ЗН-0167347", "company_id"=>"ЛУКАВТО (ЛУКОЙЛ-Центрнефтепродукт)", "Марка ТС"=>"MERCEDES-BENZ", "Модель ТС"=>"S450", "carnumber"=>"А377АА777", "detal title"=>"РЕШЕТКА ПЕРЕДНЕГО БАМПЕРА", "date"=>"2023-06-02", "sum"=>"", "totalsum"=>"", "katnumber"=>"A2228857100"}, 
                {"region"=>"МСК", "strah_id"=>"Альфа", "unumber"=>"0191/046/00098/23", "stoanumber"=>"ЗН-0167347", "company_id"=>"ЛУКАВТО (ЛУКОЙЛ-Центрнефтепродукт)", "Марка ТС"=>"MERCEDES-BENZ", "Модель ТС"=>"S450", "carnumber"=>"А377АА777", "detal title"=>"МОЛДИНГ ПЕРЕДНЕГО БАМПЕРА", "date"=>"2023-06-02", "sum"=>"", "totalsum"=>"", "katnumber"=>"A2228857600"}, 
                {"region"=>"МСК", "strah_id"=>"Альфа", "unumber"=>"0191/046/00098/23", "stoanumber"=>"ЗН-0167347", "company_id"=>"ЛУКАВТО (ЛУКОЙЛ-Центрнефтепродукт)", "Марка ТС"=>"MERCEDES-BENZ", "Модель ТС"=>"S450", "carnumber"=>"А377АА777", "detal title"=>"НАКЛАДКА БАМПЕРА ЛЕВАЯ", "date"=>"2023-06-02", "sum"=>"", "totalsum"=>"", "katnumber"=>"A2228857700"}, 
                {"region"=>"МСК", "strah_id"=>"Альфа", "unumber"=>"0191/046/00098/23", "stoanumber"=>"ЗН-0167347", "company_id"=>"ЛУКАВТО (ЛУКОЙЛ-Центрнефтепродукт)", "Марка ТС"=>"MERCEDES-BENZ", "Модель ТС"=>"S450", "carnumber"=>"А377АА777", "detal title"=>"НАКЛАДКА БАМПЕРА ПРАВАЯ", "date"=>"2023-06-02", "sum"=>"", "totalsum"=>"", "katnumber"=>"A2228857800"} 
            ]
        end

    end
end