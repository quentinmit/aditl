var ITEM_SIZE=380;
var OVERSHOOT=2;
var MINUTES_PER_ITEM=12;
var MINUTES_PER_DAY=1440;

var shown_xoffs = [];

function update_timeline(scroll_position) {
    var container = $("#timeline-container");

    var container_width = container.outerWidth();

    var left_edge = scroll_position - OVERSHOOT * ITEM_SIZE;
    var right_edge = scroll_position + container_width + OVERSHOOT * ITEM_SIZE;

    $("#timeline-container .scrollview-content").css("width", ""+(ITEM_SIZE * 1440 / MINUTES_PER_ITEM)+"px");

    $.each(timeline_images, function(index, bucket) {
	if ($.inArray(bucket.xoff, shown_xoffs) < 0) {
	    if (bucket.xoff > left_edge && bucket.xoff < right_edge) {
		var scrollview_item = $('<div class="scrollview-item"></div>');

		scrollview_item.css("left", ""+bucket.xoff+"px");

		$.each(bucket.photos, function(index, photo) {
		    var this_image = $('<div id="photo-'+photo.phid+'"><div class="image"><img src="'+photo.image+'"></div><div class="info"><article><h2>'+photo.time+'</h2></article></div></div>');
		    var article = this_image.find("article");
		    article.append($("<p></p>").text(photo.caption));

		    if (index > 0) {
			this_image.css("display", "none");
		    }
		    scrollview_item.append(this_image);
		});

		if (bucket.even) {
		    scrollview_item.addClass("even");
		}

		$("#timeline-container .scrollview-content").append(scrollview_item);

		container[0].relayout(true);
		//appendItem(scrollview_item[0]);

		shown_xoffs.push(bucket.xoff);
	    }
	}
    });
}

$(function() {
    var container = $("#timeline-container")[0];
    var container_width = $("#timeline-container").outerWidth();
    slider = $("#timeline-slider").slider({
	min: 0,
	max: MINUTES_PER_DAY / MINUTES_PER_ITEM * ITEM_SIZE,
	slide: function (event, ui) {
	    container.moveTo({x:-ui.value, y:0});
	    update_timeline(ui.value);
	},
    });
    update_timeline(0);
    container.onmove = function(e) {
	var x = -e.getX();
	slider.slider("value", x);
	update_timeline(x);
    };

    $(".pagination-arrow.next").click(function (e) {
	container.scrollTo({x:container.getX()-container_width, y:0});
    });
    $(".pagination-arrow.prev").click(function (e) {
	container.scrollTo({x:container.getX()+container_width, y:0});
    });
});
