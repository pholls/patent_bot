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

  font 'Times_New_Roman'
end
