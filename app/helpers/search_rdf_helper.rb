module SearchRdfHelper

  def layout_param
    if params[:spotlight]
      "&layout=#{params[:spotlight]}"
    else
      ""
    end
  end
end
