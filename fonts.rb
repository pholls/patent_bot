def add_fonts
  font_path = "./assets/fonts/Times_New_Roman/"
  font_families.update(
    "Times_New_Roman" => {
      normal: "#{font_path}Times_New_Roman.ttf",
      italic: "#{font_path}Times_New_Roman_Italic.ttf",
      bold: "#{font_path}Times_New_Roman_Bold.ttf",
      bold_italic: "#{font_path}Times_New_Roman_Bold_Italic.ttf"
    }
  )

  font_path = "./assets/fonts/IPA/"
  font_families.update(
    "IPA" => {
      normal: "#{font_path}ipamp.ttf",
      bold: "#{font_path}ipag.ttf"
    }
  )

  font_path = "./assets/fonts/DejaVu/"
  font_families.update(
    "DejaVuSans" => {
      normal: "#{font_path}DejaVuSans.ttf",
      bold: "#{font_path}DejaVuSans-Bold.ttf"
    }
  )

  font_path = "./assets/fonts/DejaVu/"
  font_families.update(
    "DejaVuSerif" => {
      normal: "#{font_path}DejaVuSerif.ttf",
      bold: "#{font_path}DejaVuSerif-Bold.ttf",
      italic: "#{font_path}DejaVuSerif-Italic.ttf",
      bold_italic: "#{font_path}DejaVuSerif-BoldItalic.ttf"
    }
  )

  font_path = "./assets/fonts/Arial/"
  font_families.update(
    "Arial" => {
      normal: "#{font_path}Arial.ttf",
      bold: "#{font_path}Arial Bold.ttf",
      italic: "#{font_path}Arial Italic.ttf",
      bold_italic: "#{font_path}Arial Bold Italic.ttf"
    }
  )

  font 'Times_New_Roman'

  fallback_fonts ["IPA", "Times_New_Roman"]
  fallback_fonts ["Times-Roman", "Times_New_Roman"]
end
