module ApplicationHelper
  def nav_link_classes(path)
    if current_page?(path)
      "flex items-center gap-3 px-3 py-2.5 rounded-lg bg-green-800 text-white font-semibold"
    else
      "flex items-center gap-3 px-3 py-2.5 rounded-lg text-gray-600 font-medium hover:bg-gray-100"
    end
  end
end
