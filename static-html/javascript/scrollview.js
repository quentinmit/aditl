// ---
// Copyright (c) 2011 Francesco Cottone, http://www.kesiev.com/
// ---

var scrollview={
	_default:{
		scrollviewbarscolor:"#505050",
		scrollviewitemscolor:"",
		scrollviewbulletcolor:"#a0a0a0",
		scrollviewselectedbulletcolor:"#e0e0e0",
		scrollviewwheelsensitivity:6,
		pulsebarsfor:40,
		pulsebarsfadedime:20,
		barszindex:10
	},
	_hardware:{touchenabled:false, transform:null,borderRadius:null,fps:25},
	_framehandler:{queue:[]},
	_scrollviews:[],
	_scrollviewevents:["onstartspring","onendspring","onstartdragging","onenddragging","ondragging","onitemselected","onmove","onrelayout"],
	
	// Utils
	_mth:function(w,z) { return (w/2)-(w*z/2)},
	displaceobj:function(obj,x,y,zoom) {
		obj.style[this._hardware.transform.js]="translate("+(x-this._mth(obj.offsetWidth,zoom))+"px,"+(y-this._mth(obj.offsetHeight,zoom))+"px) scale("+zoom+")";
	},

	applyTouchEvents:function(dest,touchstart,touchmove,touchend,idlecheck,applyto) {
		var self=this;
		if (idlecheck) {
			if (!this._hardware.touchenabled) { // Enable the virtual touch if is not a touch interface.
				if (touchstart) this.addEventListener(dest,"mousedown",function(e){if (!idlecheck()) return; e.touches=[{identifier:1,clientX:e.pageX,clientY:e.pageY}];e.mouseWrapper=true;if (this.ontouchstart) this.ontouchstart.apply((applyto?applyto:this),[e,self,applyto]);});
				if (touchmove) this.addEventListener(dest,"mousemove",function(e){if (!idlecheck()) return; e.stopPropagation(); if (this.ontouchmove) {e.touches=[{identifier:1,clientX:e.pageX,clientY:e.pageY}];e.mouseWrapper=true;this.ontouchmove.apply((applyto?applyto:this),[e,self,applyto]);}});
				if (touchend) this.addEventListener(dest,"mouseup",function(e){if (!idlecheck()) return; e.stopPropagation();if(this.ontouchend){e.touches=[];e.mouseWrapper=true;this.ontouchend.apply((applyto?applyto:this),[e,self,applyto]);}});
			}
			dest.ontouchstart=function(e) { if (idlecheck()) return touchstart.apply((applyto?applyto:this),[e,self,applyto]); }
			dest.ontouchmove=function(e) { if (idlecheck()) return touchmove.apply((applyto?applyto:this),[e,self,applyto]);}
			dest.ontouchend=function(e) { if (idlecheck()) return touchend.apply((applyto?applyto:this),[e,self,applyto]); }
			dest.ontouchcancel=function(e) { if (idlecheck()) return touchend.apply((applyto?applyto:this),[e,self,applyto]); }
		} else {
			if (!this._hardware.touchenabled) { // Enable the virtual touch if is not a touch interface.
				if (touchstart) this.addEventListener(dest,"mousedown",function(e){e.touches=[{identifier:1,clientX:e.pageX,clientY:e.pageY}];e.mouseWrapper=true;if (this.ontouchstart) this.ontouchstart.apply((applyto?applyto:this),[e,self,applyto]);});
				if (touchmove) this.addEventListener(dest,"mousemove",function(e){e.stopPropagation(); if (this.ontouchmove) {e.touches=[{identifier:1,clientX:e.pageX,clientY:e.pageY}];e.mouseWrapper=true;this.ontouchmove.apply((applyto?applyto:this),[e,self,applyto]);}});
				if (touchend) {
					this.addEventListener(dest,"mouseup",function(e){e.stopPropagation();if(this.ontouchend){e.touches=[];e.mouseWrapper=true;this.ontouchend.apply((applyto?applyto:this),[e,self,applyto]);}});
					$(dest).mouseleave(function(e){
							e.stopPropagation();
							if(this.ontouchend){e.touches=[];e.mouseWrapper=true;this.ontouchend.apply((applyto?applyto:this),[e,self,applyto]);}
					});
				}
			}
			dest.ontouchstart=function(e) { touchstart.apply((applyto?applyto:this),[e,self,applyto]); }
			dest.ontouchmove=function(e) { touchmove.apply((applyto?applyto:this),[e,self,applyto]);}
			dest.ontouchend=function(e) { touchend.apply((applyto?applyto:this),[e,self,applyto]); }
			dest.ontouchcancel=function(e) { touchend.apply((applyto?applyto:this),[e,self,applyto]); }
		}
	},
	addEventListener:function(to,event,code) {
		if (to.addEventListener) {
			to.addEventListener(event,code,false);
			if (event=="mousewheel") to.addEventListener("DOMMouseScroll",code,false);
		} else to.attachEvent('on'+event,code);
	},
	getElementsByClassName:function(from,cl) {
		var retnode = [];
		var myclass = new RegExp('\\b'+cl+'\\b');
		var elem = from.getElementsByTagName('*');
		for (var i = 0; i < elem.length; i++) {
		var classes = elem[i].className;
		if (myclass.test(classes)) retnode.push(elem[i]);
		}
		return retnode;
	},
	// Dragevents
	_disabledrag:function(e) {if(e.preventDefault) e.preventDefault()},
	_touchstart:function(e) {
		if ((this.getAttribute("scrollviewenabled")!="no")&&!this.__drg.pos.dragging&&!this.__drg.pos.springing) {
			//this.__drg.pos.parents=scrollview.getElementsByClassName(this.__drg.pos.content,"scrollview-container");
			this.__drg.pos.sidelocked=0;
			this.__drg.pos.dragging=true;
			this.__drg.pos.drag={x:e.touches[0].clientX,y:e.touches[0].clientY,drag:false}
			this.__drg.pos.pulsebars=scrollview._default.pulsebarsfor;
			scrollview.stopspringing();
			scrollview.startanimating(this);
			scrollview.displacebars(this);
		}
	},
	_touchend:function(e) {
		if (e) {e.preventDefault();e.stopPropagation();}
		if (this.__drg.pos.dragging) {
			if (this.onenddragging) this.onenddragging(this);
			this.__drg.pos.dragging=false;
			this.__drg.pos.x+=this.__drg.pos.gap.x;
			this.__drg.pos.y+=this.__drg.pos.gap.y;
			this.__drg.pos.gap={x:0,y:0};
			if (!this.__drg.pos.springto) {
				scrollview.applyspring(this);
				scrollview.startanimating(this);
			}
			var pn=this;
			while (pn.parentNode) {
				pn=pn.parentNode;
				if (pn.__drg&&pn.__drg.pos.dragging) pn.ontouchend();
			}
		}
	},
	_touchmove:function(e,a,b,gap) {
		if (!e.__gap) { e.preventDefault();e.stopPropagation(); }
		if (this.__drg.pos.dragging) {
			if (e.__gap)
				this.__drg.pos.gap=e.__gap;
			else {
				var hit={x:e.touches[0].clientX,y:e.touches[0].clientY};
				this.__drg.pos.gap={x:hit.x-this.__drg.pos.drag.x,y:hit.y-this.__drg.pos.drag.y}
			}
			if (!this.__drg.pos.drag.drag) {
				if ((Math.abs(this.__drg.pos.gap.y) > 10) || (Math.abs(this.__drg.pos.gap.x) > 10)) {
					this.__drg.pos.drag.drag=true;
					if (this.onstartdragging) this.onstartdragging(this);
				}
			} else if (this.ondragging) this.ondragging(this);
			if (this.getAttribute("scrollviewsingleside")=="yes") {
				if (!this.__drg.pos.sidelocked) {
					if (Math.abs(this.__drg.pos.gap.x)>5) this.__drg.pos.sidelocked=1; else
					if (Math.abs(this.__drg.pos.gap.y)>5) this.__drg.pos.sidelocked=2;
				}
				if (!this.__drg.pos.sidelocked||(this.__drg.pos.sidelocked==1)) this.__drg.pos.gap.y=0;
				if (!this.__drg.pos.sidelocked||(this.__drg.pos.sidelocked==2)) this.__drg.pos.gap.x=0;
			}
			var passedgap={x:0,y:0};
			if (this.getAttribute("scrollviewenabledscrollx")=="no") {
				passedgap.x=this.__drg.pos.gap.x;
				this.__drg.pos.gap.x=0;
			} else if (this.getAttribute("scrollviewspringx")=="no") {
				if (this.__drg.pos.gap.x+this.__drg.pos.x>0) {
					passedgap.x=this.__drg.pos.gap.x+this.__drg.pos.x;
					this.__drg.pos.gap.x=-this.__drg.pos.x;
				} else if (this.__drg.pos.gap.x+this.__drg.pos.x+this.__drg.pos.content.offsetWidth<this.offsetWidth) {
					passedgap.x=this.__drg.pos.gap.x+this.__drg.pos.x+this.__drg.pos.content.offsetWidth-this.offsetWidth;
					this.__drg.pos.gap.x=this.offsetWidth-this.__drg.pos.content.offsetWidth-this.__drg.pos.x;
				}
			}
			if (this.getAttribute("scrollviewenabledscrolly")=="no") {
				passedgap.y=this.__drg.pos.gap.y;
				this.__drg.pos.gap.y=0;						
			} else if (this.getAttribute("scrollviewspringy")=="no") {
				if (this.__drg.pos.gap.y+this.__drg.pos.y>0) {
					passedgap.y=this.__drg.pos.gap.y+this.__drg.pos.y;
					this.__drg.pos.gap.y=-this.__drg.pos.y;
				} else if (this.__drg.pos.gap.y+this.__drg.pos.y+this.__drg.pos.content.offsetHeight<this.offsetHeight) {
					passedgap.y=this.__drg.pos.gap.y+this.__drg.pos.y+this.__drg.pos.content.offsetHeight-this.offsetHeight;
					this.__drg.pos.gap.y=this.offsetHeight-this.__drg.pos.content.offsetHeight-this.__drg.pos.y;
				}
			}
			this.__drg.pos.dirty=true;
			var pn=this;
			while (pn.parentNode) {
				pn=pn.parentNode;
				if (pn.__drg&&pn.__drg.pos.dragging) { 
					e.__gap=passedgap;
					pn.ontouchmove(e);
					break
				}
			}
		}
	},
	_onwheel:function(e){
		var consumed=false;
		if (this.__drg.pos.springing) {
			consumed=true;
		} else if (this.getAttribute("scrollviewenabled")!="no") {
			var delta = 0;
			var axis=0;
			if (e.axis) axis=(e.axis == e.HORIZONTAL_AXIS?1:2);
			else if (e.wheelDeltaX) axis=1; else if (e.wheelDeltaY) axis=2;
			if (!e) e = window.e;
			if (e.wheelDelta) {
				delta = e.wheelDelta/120;
				if (window.opera) delta = -delta;
			} else if (e.detail) delta = -e.detail/3;
			delta=delta*(this.getAttribute("scrollviewwheelsensitivity")?this.getAttribute("scrollviewwheelsensitivity")*1:scrollview._default.scrollviewwheelsensitivity);
			if (Math.abs(delta)>3) {
				if ((!axis||(axis==2))&&(this.getAttribute("scrollviewenabledscrolly")!="no")) {
					if (this.getAttribute("scrollviewsnapy")=="yes") {
						if (delta>0) delta=1; else delta=-1;
						var current=this.getCurrentItem();
						if (current) {
							var scrollto=this.getItemAtIndex(current.index+delta);
							if (scrollto) {
								this.scrollToItemAtIndex(current.index+delta);
								consumed=true;
							}
						}
					} else {
						var old=this.__drg.pos.y;
						this.__drg.pos.y+=delta;
						scrollview.applyspring(this);
						if (this.__drg.pos.springto.y!=old) {
							scrollview.cancelspring(this);
							this.pulseBars();
							consumed=true;
						} else this.__drg.pos.y=old;
					}
				} else if ((!axis||(axis==1))&&this.getAttribute("scrollviewenabledscrollx")!="no") {
					if (this.getAttribute("scrollviewsnapx")=="yes") {
						if (delta>0) delta=1; else delta=-1;
						var current=this.getCurrentItem();
						if (current) {
							var scrollto=this.getItemAtIndex(current.index+delta);
							if (scrollto) {
								this.scrollToItemAtIndex(current.index+delta);
								consumed=true;
							}
						}
					} else {
						var old=this.__drg.pos.x;
						this.__drg.pos.x+=delta;
						scrollview.applyspring(this);
						if (this.__drg.pos.springto.x!=old) {
							scrollview.cancelspring(this);
							this.pulseBars();
							consumed=true;
						} else this.__drg.pos.springto.x=old;
					}
				}
			}
		}
	    if (consumed) {
		e.preventDefault();
		e.stopPropagation();
	    }
	},
	// Content handler
	cancelspring:function(obj) {
		obj.__drg.pos.x=obj.__drg.pos.springto.x;
		obj.__drg.pos.y=obj.__drg.pos.springto.y;
		obj.__drg.pos.springto=null;
		this.displacescroll(obj);
		if (obj.onitemselected&&obj.getCurrentItem()) obj.onitemselected(obj);
	},
	applyspring:function(obj) {
		var ythreshold=obj.__drg.pos.content.offsetHeight-obj.offsetHeight;
		var xthreshold=obj.__drg.pos.content.offsetWidth-obj.offsetWidth;
		var steps={x:[0,xthreshold],y:[0,ythreshold]};
		for (var i=0;i<obj.__drg.pos.content.childNodes.length;i++) 
			if (scrollview._itemregexp.test(obj.__drg.pos.content.childNodes[i].className)) {
				if (obj.__drg.pos.content.childNodes[i].offsetTop<ythreshold) steps.y.push(obj.__drg.pos.content.childNodes[i].offsetTop);
				if (obj.__drg.pos.content.childNodes[i].offsetTop+obj.__drg.pos.content.childNodes[i].offsetHeight<ythreshold) steps.y.push(obj.__drg.pos.content.childNodes[i].offsetTop+obj.__drg.pos.content.childNodes[i].offsetHeight);
				if (obj.__drg.pos.content.childNodes[i].offsetLeft<xthreshold) steps.x.push(obj.__drg.pos.content.childNodes[i].offsetLeft);
				if (obj.__drg.pos.content.childNodes[i].offsetLeft+obj.__drg.pos.content.childNodes[i].offsetWidth<xthreshold) steps.x.push(obj.__drg.pos.content.childNodes[i].offsetLeft+obj.__drg.pos.content.childNodes[i].offsetWidth);
			}
		// Evaluate
		var tmpx=(obj.__drg.pos.springto?obj.__drg.pos.springto.x:obj.__drg.pos.x);
		var tmpy=(obj.__drg.pos.springto?obj.__drg.pos.springto.y:obj.__drg.pos.y);
		obj.__drg.pos.springto={x:null,y:null};
		var tmpdist;
		var dist;
		if (obj.getAttribute("scrollviewsnapy")=="yes") {
			dist=0;
			for (var i=0;i<steps.y.length;i++) {
				tmpdist=Math.abs(steps.y[i]+tmpy);
				if ((obj.__drg.pos.springto.y===null)||(tmpdist<dist)) { obj.__drg.pos.springto.y=-steps.y[i]; dist=tmpdist}
			}
		} else {
			obj.__drg.pos.springto.y=tmpy;
			if (obj.__drg.pos.springto.y>0) obj.__drg.pos.springto.y=0; else
			if (obj.__drg.pos.content.offsetHeight+obj.__drg.pos.springto.y<obj.offsetHeight) obj.__drg.pos.springto.y=obj.offsetHeight-obj.__drg.pos.content.offsetHeight;								
		}
		if (obj.getAttribute("scrollviewsnapx")=="yes") {
			dist=0;
			for (var i=0;i<steps.x.length;i++) {
				tmpdist=Math.abs(steps.x[i]+tmpx);
				if ((obj.__drg.pos.springto.x===null)||(tmpdist<dist)) {obj.__drg.pos.springto.x=-steps.x[i]; dist=tmpdist}
			}
		} else {
			obj.__drg.pos.springto.x=tmpx;
			if (obj.__drg.pos.springto.x>0) obj.__drg.pos.springto.x=0; else
			if (obj.__drg.pos.content.offsetWidth+obj.__drg.pos.springto.x<obj.offsetWidth) obj.__drg.pos.springto.x=obj.offsetWidth-obj.__drg.pos.content.offsetWidth;
		}
	},
	displacescroll:function(obj) {
		this.displaceobj(obj.__drg.pos.content,obj.__drg.pos.x+obj.__drg.pos.gap.x,obj.__drg.pos.y+obj.__drg.pos.gap.y,1);
		this.displacebars(obj);
	},
	// Frame handler
	framehandler:function() {
		var i=0;
		var updategui;
		var updatebars;
		var reschedule=false;
		var gap;
		while (i<scrollview._framehandler.queue.length) {
			updategui=false;
			updatebars=false;
			var obj=scrollview._framehandler.queue[i];
			if (obj.__drg.pos.springto) {
				if (obj.__drg.pos.springto.x!=obj.__drg.pos.x) {
					gap=(obj.__drg.pos.springto.x-obj.__drg.pos.x)/2;
					if (Math.abs(gap)<1) obj.__drg.pos.x=obj.__drg.pos.springto.x; else obj.__drg.pos.x+=gap;
					updategui=true;
				}
				if (obj.__drg.pos.springto.y!=obj.__drg.pos.y) {
					gap=(obj.__drg.pos.springto.y-obj.__drg.pos.y)/2;
					if (Math.abs(gap)<1) obj.__drg.pos.y=obj.__drg.pos.springto.y; else obj.__drg.pos.y+=gap;
					updategui=true;
				}
			}
			if (!obj.__drg.pos.dragging&&(obj.__drg.pos.pulsebars>0)) {
				obj.__drg.pos.pulsebars--;
				updatebars=true;
			}
			if (updategui) {
				if (!obj.__drg.pos.springing) {
					if (obj.onstartspring) obj.onstartspring(obj);
					obj.__drg.pos.springing=true;
				}
				obj.__drg.pos.dirty=true;
			} else {
				if (obj.__drg.pos.springto) {
					if (obj.onitemselected&&obj.getCurrentItem()) obj.onitemselected(obj);
					if (obj.__drg.pos.springing) {
						if (obj.onendspring) obj.onendspring(obj);
						obj.__drg.pos.springing=false;
						scrollview.springedbars(obj);
					}
					obj.__drg.pos.springto=null;
				}
			}
			if (obj.__drg.pos.dirty) {
				scrollview.displacescroll(obj);
				if (obj.onmove) obj.onmove(obj);
				obj.__drg.pos.dirty=false;
			}
			if (updatebars) scrollview.displacebars(obj);
			if (updategui||updatebars||obj.__drg.pos.dragging)
				i++;
			else {
				obj.__drg.pos.animating=false;
				scrollview._framehandler.queue.splice(i,1);
			}
			reschedule=reschedule||updategui||updatebars||obj.__drg.pos.dragging;
		}
		if (reschedule)
			scrollview._framehandler.timer=setTimeout(scrollview.framehandler,scrollview._hardware.mspf);
		else
			scrollview._framehandler.timer=null;
	},
	stopspringing:function() {
		if (scrollview._framehandler.timer) {
			clearTimeout(scrollview._framehandler.timer);
			scrollview._framehandler.timer=null;
		}
	},
	startanimating:function(view) {
		if (view) {
			if (!view.__drg.pos.animating) {
				view.__drg.pos.animating=true;
				this._framehandler.queue.push(view);
			}
		}
		if (!this._framehandler.timer) this.framehandler();
	},
	// INIT
	init:function() {
		// Feature detection
		var s = document.body.style;

		// Detect CSS transform
		if (s.transform !== undefined) scrollview._hardware.transform={js:"transform",style:"transform"}; else
		if (s.WebkitTransform !== undefined) scrollview._hardware.transform={js:"WebkitTransform",style:"-webkit-transform"}; else
		if (s.MozTransform !== undefined) scrollview._hardware.transform={js:"MozTransform",style:"-moz-transform"};
		if (s.OTransform !== undefined) scrollview._hardware.transform={js:"OTransform",style:"-o-transform"}; // Opera translations are slower than moving?
		
		// Detect CSS BorderRadius	
		if (s.borderRadius !== undefined) scrollview._hardware.borderradius={js:"borderRadius",style:"border-radius"}; else
		if (s.WebkitBorderRadius !== undefined) scrollview._hardware.borderradius={js:"WebkitBorderRadius",style:"-webkit-border-radius"}; else
		if (s.MozBorderRadius !== undefined) scrollview._hardware.borderradius={js:"MozBorderRadius",style:"-moz-border-radius"}; else
		if (s.OBorderRadius !== undefined) scrollview._hardware.borderradius={js:"OBorderRadius",style:"-o-border-radius"};
		
		// FPS-to-time
		scrollview._hardware.mspf=Math.ceil(1000/scrollview._hardware.fps);
					
		// Touch support
		var el = document.createElement('div');
		el.setAttribute('ontouchstart', 'return;');
		scrollview._hardware.touchenabled=(typeof el.ontouchstart == "function");	
		
		// Prepare regexp
		scrollview._itemregexp = new RegExp('\\bscrollview-item\\b');
		
		// Resize event
		scrollview.addEventListener(window,"resize",scrollview.resizeevent);
		
		// Autoapply scroll views.
		var contentregexp=new RegExp('\\bscrollview-content\\b');;
		var containers=scrollview.getElementsByClassName(document.body,"scrollview-container");
		for (var a=0;a<containers.length;a++) {
			for (var j=0;j<containers[a].childNodes.length;j++)
				if (containers[a].childNodes[j].className&&contentregexp.test(containers[a].childNodes[j].className)) {
					scrollview.create(containers[a],containers[a].childNodes[j]);
					break;
				}
		}
		
		// Ontap auto support
		var elem = document.body.getElementsByTagName('*');
		for (var i=0;i<elem.length;i++)
			if (elem&&elem[i]&&elem[i].getAttribute&&elem[i].getAttribute("ontap"))
				scrollview.onTap(elem[i],new Function(elem[i].getAttribute("ontap")));

		var elem = document.body.getElementsByTagName('a');
		for (var i=0;i<elem.length;i++) {
			scrollview.disableDrag(elem[i]);
			scrollview.addEventListener(elem[i],"click",function(e) {
				if (scrollview.clickCancelled(this)) {
					scrollview._disabledrag(e);
					return false;
				}
				else return true;
			});
		}
		
		scrollview.disableDrag(document.body);

				
		// Disable drag via className
		var elem = document.body.getElementsByClassName('scrollview-disabledrag');
		for (var i=0;i<elem.length;i++) scrollview.disableDrag(elem[i]);
		
	},
	// SCROLLVIEW/CONTENT PROTOTYPE
	_scrollviewprototype:{
		getX:function() { return this.__drg.pos.x+this.__drg.pos.gap.x; },
		getY:function() { return this.__drg.pos.y+this.__drg.pos.gap.y; },
		getIndexOfItem:function(obj) {
			var pos=0;
			for (var i=0;i<this.__drg.pos.content.childNodes.length;i++) 
				if (scrollview._itemregexp.test(this.__drg.pos.content.childNodes[i].className)) {
					if (this.__drg.pos.content.childNodes[i]==obj)
						return {object:this.__drg.pos.content.childNodes[i],index:pos,childid:i};
					pos++;
				}
			return null;
		},
		getCurrentItem:function() {
			var pos=0;
			var center={x:this.__drg.pos.x,y:this.__drg.pos.y};
			for (var i=0;i<this.__drg.pos.content.childNodes.length;i++) 
				if (scrollview._itemregexp.test(this.__drg.pos.content.childNodes[i].className)) {
					if ((Math.abs(this.__drg.pos.content.childNodes[i].offsetLeft+this.__drg.pos.x)<5)&&(Math.abs(this.__drg.pos.content.childNodes[i].offsetTop+this.__drg.pos.y)<5))
						return {object:this.__drg.pos.content.childNodes[i],index:pos,childid:i};
					pos++;
				}
			return null;
		},
		scrollTo:function(coord) {
			this.__drg.pos.springto=coord;
			scrollview.applyspring(this);
			scrollview.startanimating(this);
		},
		scrollToTop:function() {
			this.scrollTo({x:this.__drg.pos.x,y:0});
		},
		scrollToBottom:function() {
			this.scrollTo({x:this.__drg.pos.x,y:this.offsetHeight-this.__drg.pos.content.offsetHeight});
		},
		scrollToBeginning:function() {
			this.scrollTo({x:0,y:this.__drg.pos.y});
		},
		scrollToEnd:function() {
			this.scrollTo({x:this.offsetWidth-this.__drg.pos.content.offsetWidth,y:0});
		},
		scrollToItem:function(obj) {
			if (obj) {
				this.scrollTo({x:-obj.offsetLeft,y:-obj.offsetTop});
				return true;
			} else return false;
		},
		getItemsCount:function() {
			var pos=0;
			for (var i=0;i<this.__drg.pos.content.childNodes.length;i++) 
				if (scrollview._itemregexp.test(this.__drg.pos.content.childNodes[i].className)) pos++;
			return pos;				
		},
		getItemAtIndex:function(idx) {
			var pos=0;
			for (var i=0;i<this.__drg.pos.content.childNodes.length;i++) 
				if (scrollview._itemregexp.test(this.__drg.pos.content.childNodes[i].className))
					if (pos==idx) return this.__drg.pos.content.childNodes[i]; else pos++;
			return null;
		},
		scrollToItemAtIndex:function(idx) {
			return this.scrollToItem(this.getItemAtIndex(idx));
		},
		moveTo:function(coord) {
			this.__drg.pos.springto=coord;
			scrollview.applyspring(this);
			scrollview.cancelspring(this);
		},
		moveToTop:function() {
			this.moveTo({x:this.__drg.pos.x,y:0});
		},
		moveToBottom:function() {
			this.moveTo({x:this.__drg.pos.x,y:this.offsetHeight-this.__drg.pos.content.offsetHeight});
		},
		moveToBeginning:function() {
			this.moveTo({x:0,y:this.__drg.pos.y});
		},
		moveToEnd:function() {
			this.moveTo({x:this.offsetWidth-this.__drg.pos.content.offsetWidth,y:0});
		},
		moveToItem:function(obj) {
			if (obj) {
				this.moveTo({x:-obj.offsetLeft,y:-obj.offsetTop});
				return true;
			} else return false;
		},
		moveToItemAtIndex:function(idx) {
			return this.moveToItem(this.getItemAtIndex(idx));
		},
		relayout:function(onlyme) {
			if (onlyme)
				scrollview.relayout(this);
			else
				scrollview.broadcastRelayout(this);
		},
		removeItem:function(obj) {
			if (obj) {
				this.__drg.pos.content.removeChild(obj);
				scrollview.relayout(this);
				scrollview.applyspring(this);
				return true;
			} else return false;
		},
		removeItemAtIndex:function(idx) {
			return this.removeItem(this.getItemAtIndex(idx));
		},
		appendItem:function(obj) {
			if (!scrollview._itemregexp.test(obj.className)) obj.className+=" scrollview-item";
			this.__drg.pos.content.appendChild(obj);
			scrollview.relayout(this);
			scrollview.applyspring(this);
			scrollview.startanimating(this);
		},
		appendItemBefore:function(obj,bef) {
			if (!scrollview._itemregexp.test(obj.className)) obj.className+=" scrollview-item";
			this.__drg.pos.content.insertBefore(obj,bef);
			scrollview.relayout(this);
			scrollview.applyspring(this);
			scrollview.startanimating(this);
		},
		appendItemAfter:function(obj,bef) {
			if (!scrollview._itemregexp.test(obj.className)) obj.className+=" scrollview-item";
			if (bef.nextSibling)
				this.__drg.pos.content.insertBefore(obj, bef.nextSibling);
			else
				this.__drg.pos.content.appendChild(obj);
			scrollview.relayout(this);
			scrollview.applyspring(this);
			scrollview.startanimating(this);
		},
		setBars:function(value) {
			this.setAttribute("scrollviewbars",value);
			scrollview.switchbarmode(this);
		},
		pulseBars:function() {
			this.__drg.pos.pulsebars=scrollview._default.pulsebarsfor;
			scrollview.startanimating(this);
		},
		getContent:function() {
			return this.__drg.pos.content;
		}		
	},
	_scrollviewcontentprototype:{
		getContainer:function() {
			return this.__drg.pos.container;
		},
		relayout:function(onlyme) {
			var container=this.getContainer();
			container.relayout(onlyme);
		}
	},
	// MAIN
	springedbars:function(container) {
		if (container.getAttribute("scrollviewbars")=="items") {
			var ret="";
			var sel=container.getCurrentItem();
			if (sel) sel=sel.index; else sel=-1;
			var cnt=container.getItemsCount();
			for (var i=0;i<cnt;i++)
				ret+="<span style='color:"+(
					sel==i?
					(container.getAttribute("scrollviewselectedbulletcolor")?container.getAttribute("scrollviewselectedbulletcolor"):scrollview._default.scrollviewselectedbulletcolor):
					(container.getAttribute("scrollviewbulletcolor")?container.getAttribute("scrollviewbulletcolor"):scrollview._default.scrollviewbulletcolor)
				)+"'>&bull;</span>";
			container.__drg.pos.bars[0].innerHTML=ret;
		}
	},
	displacebars:function(container) {
		if ((container.getAttribute("scrollviewbars")=="both")||(container.getAttribute("scrollviewbars")=="horizontal"))
			if (container.__drg.pos.pulsebars) {
				var sw=container.offsetWidth-10;
				var w=(sw*container.offsetWidth/container.__drg.pos.content.offsetWidth);
				var l=(-((container.__drg.pos.x+container.__drg.pos.gap.x)/container.__drg.pos.content.offsetWidth)*sw);
				if (l<0) {w+=l; l=0;};
				if (l+w>sw) w=sw-l;
				if (w<5) w=5;
				if (l+w>sw) l=sw-w;
				if (w==sw) {
					if (container.__drg.pos.bars[0].parentNode) container.removeChild(container.__drg.pos.bars[0]);
				} else {
					container.__drg.pos.bars[0].style.opacity=(container.__drg.pos.pulsebars>scrollview._default.pulsebarsfadedime?1:container.__drg.pos.pulsebars/scrollview._default.pulsebarsfadedime);
					container.__drg.pos.bars[0].style.width=w+"px";
					container.__drg.pos.bars[0].style.left=(5+l)+"px";
					container.__drg.pos.bars[0].style.display="block";
					if (!container.__drg.pos.bars[0].parentNode) container.appendChild(container.__drg.pos.bars[0]);
				}						
			} else if (container.__drg.pos.bars[0].parentNode) container.removeChild(container.__drg.pos.bars[0]);
		if ((container.getAttribute("scrollviewbars")=="both")||(container.getAttribute("scrollviewbars")=="vertical"))
			if (container.__drg.pos.pulsebars) {
				var sh=container.offsetHeight-10;
				var h=(sh*container.offsetHeight/container.__drg.pos.content.offsetHeight);
				var t=(-((container.__drg.pos.y+container.__drg.pos.gap.y)/container.__drg.pos.content.offsetHeight)*sh);
				if (t<0) {h+=t; t=0;};
				if (t+h>sh) h=sh-t;
				if (h<5) h=5;
				if (t+h>sh) t=sh-h;
				if (h==sh) {
					if (container.__drg.pos.bars[1].parentNode) container.removeChild(container.__drg.pos.bars[1]);
				} else {
					container.__drg.pos.bars[1].style.opacity=(container.__drg.pos.pulsebars>scrollview._default.pulsebarsfadedime?1:container.__drg.pos.pulsebars/scrollview._default.pulsebarsfadedime);						
					container.__drg.pos.bars[1].style.height=h+"px";
					container.__drg.pos.bars[1].style.top=(5+t)+"px";
					container.__drg.pos.bars[1].style.display="block";
					if (!container.__drg.pos.bars[1].parentNode) container.appendChild(container.__drg.pos.bars[1]);
				}
			} else if (container.__drg.pos.bars[1].parentNode) container.removeChild(container.__drg.pos.bars[1]);
	},
	switchbarmode:function(container) {
		for (var i=0;i<container.__drg.pos.bars.length;i++) 
			if (container.__drg.pos.bars[i].parentNode) container.__drg.pos.bars[i].parentNode.removeChild(container.__drg.pos.bars[i]);
		if ((container.getAttribute("scrollviewbars")=="both")||(container.getAttribute("scrollviewbars")=="horizontal")) {
			container.__drg.pos.bars[0].innerHTML="";
			container.__drg.pos.bars[0].style.zIndex=scrollview._default.barszindex;
			container.__drg.pos.bars[0].style.backgroundColor=(container.getAttribute("scrollviewbarscolor")?container.getAttribute("scrollviewbarscolor"):this._default.scrollviewbarscolor);
			container.__drg.pos.bars[0].style.height="5px";
			container.__drg.pos.bars[0].style.bottom="5px";
			container.__drg.pos.bars[0].style[this._hardware.borderradius.js]="5px";
		}
		if ((container.getAttribute("scrollviewbars")=="both")||(container.getAttribute("scrollviewbars")=="vertical")) {
			container.__drg.pos.bars[1].innerHTML="";
			container.__drg.pos.bars[1].style.zIndex=scrollview._default.barszindex;
			container.__drg.pos.bars[1].style.backgroundColor=(container.getAttribute("scrollviewbarscolor")?container.getAttribute("scrollviewbarscolor"):this._default.scrollviewbarscolor);
			container.__drg.pos.bars[1].style.width="5px";
			container.__drg.pos.bars[1].style.right="5px";
			container.__drg.pos.bars[1].style[this._hardware.borderradius.js]="5px";
		}
		if (container.getAttribute("scrollviewbars")=="items") {
			container.__drg.pos.bars[0].innerHTML="&bull;";
			container.__drg.pos.bars[0].style.textAlign="center";
			container.__drg.pos.bars[0].style.fontSize="20px";
			container.__drg.pos.bars[0].style.letterSpacing="5px";
			container.__drg.pos.bars[0].style.zIndex=scrollview._default.barszindex;
			container.__drg.pos.bars[0].style.backgroundColor=(container.getAttribute("scrollviewbarscolor")?container.getAttribute("scrollviewbarscolor"):this._default.scrollviewitemscolor);
			container.__drg.pos.bars[0].style.width="100%";
			container.__drg.pos.bars[0].style.height="20px";
			container.__drg.pos.bars[0].style.right="0px";
			container.__drg.pos.bars[0].style.left="0px";
			container.__drg.pos.bars[0].style.bottom="0px";
			container.__drg.pos.bars[0].style[this._hardware.borderradius.js]="0px";
			container.__drg.pos.bars[0].style.opacity=1;
			if (!container.__drg.pos.bars[0].parentNode) container.appendChild(container.__drg.pos.bars[0]);
			this.springedbars(container);
		}
	},
	resizeevent:function() {
		var i=0;
		while (i<scrollview._scrollviews.length)
			if (scrollview._scrollviews[i]) {
				scrollview.relayout(scrollview._scrollviews[i]);
				i++;
			} else
				scrollview._scrollviews.splice(i,1);
	},
	relayout:function(container) {
		if (container.onrelayout) container.onrelayout(container);
		var oldposition=container.getCurrentItem();
		container.style.overflow="hidden";
		container.__drg.pos.content.style.position="relative";
		container.__drg.pos.content.style.minWidth=container.offsetWidth+"px";
		container.__drg.pos.content.style.minHeight=container.offsetHeight+"px";
		var swmode=container.getAttribute("scrollviewmode");
		var itemsshown=container.getAttribute("scrollviewitemsshown");
		var autolineheight=(container.getAttribute("scrollviewautolineheight")=="yes");
		var rowheight=container.offsetHeight/(itemsshown?itemsshown:1);
		var rowwidth=container.offsetWidth/(itemsshown?itemsshown:1);
		var gap=0;
		if (swmode) {
			var items=0;
			for (var i=0;i<container.__drg.pos.content.childNodes.length;i++) 
				if (this._itemregexp.test(container.__drg.pos.content.childNodes[i].className)) {
					items++;
					switch (swmode) {
						case "column":
						case "strip": {
							container.__drg.pos.content.childNodes[i].style.width=container.offsetWidth+"px";
							container.__drg.pos.content.childNodes[i].style.height=container.offsetHeight+"px";
							container.__drg.pos.content.childNodes[i].style.position="relative";
							container.__drg.pos.content.childNodes[i].style.overflow="hidden";
							container.__drg.pos.content.childNodes[i].style.cssFloat="left";
							if (itemsshown) {
								container.__drg.pos.content.childNodes[i].style.width=rowwidth+"px";
								gap=container.__drg.pos.content.childNodes[i].offsetWidth-rowwidth;
								container.__drg.pos.content.childNodes[i].style.width=(rowwidth-gap)+"px";
							}
							break;
						}
						case "table": {
							//container.__drg.pos.content.childNodes[i].style.width="100%";
							if (itemsshown) {
								container.__drg.pos.content.childNodes[i].style.height=rowheight+"px";
								gap=container.__drg.pos.content.childNodes[i].offsetHeight-rowheight;
								container.__drg.pos.content.childNodes[i].style.height=(rowheight-gap)+"px";
								if (autolineheight) container.__drg.pos.content.childNodes[i].style.lineHeight=(rowheight-gap)+"px";
							}
							break;
						}
					}
				}
			switch (swmode) {
				case "strip": {
					container.__drg.pos.content.style.width=(items*rowwidth)+"px";
					break;
				}
				case "column": {
					container.__drg.pos.content.style.height=(items*rowheight)+"px";
					break;
				}
			}
		}
		if (oldposition) {
			if (container.getAttribute("scrollviewsnapx")=="yes")
				container.__drg.pos.x=-oldposition.object.offsetLeft;
			if (container.getAttribute("scrollviewsnapy")=="yes")
				container.__drg.pos.y=-oldposition.object.offsetTop;
		}
		scrollview.applyspring(container);
		scrollview.cancelspring(container);
		if (container.__drg.pos.dragging)
			container.ontouchend();
	},
 // Other code...
	// API method
	create:function(container,content) {
		if (container) {
			if (!container.className) container.className="scrollview-container"; else {
				var containerregexp=new RegExp('\\bscrollview-container\\b');
				if (!containerregexp.test(container.className)) container.className+=" scrollview-container";
			}
			if (!content) content=document.createElement("div");
			if (!content.parentNode) container.appendChild(content);
			for (var i=0;i<this._scrollviews.length;i++)
				if (this._scrollviews[i]==container) return;
			this._scrollviews.push(container);
			var bar1=document.createElement("div");
			bar1.style.display="block";
			bar1.style.position="absolute";
			var bar2=document.createElement("div");
			bar2.style.display="block";
			bar2.style.position="absolute";
			if (!container.style.position) container.style.position="relative";
			content.style.position="absolute";
			content.style.left="0px";
			content.style.top="0px";
			container.__drg={pos:{animating:false,springing:false,x:0,y:0,dragging:false,content:content,pulsebars:0,bars:[bar1,bar2],gap:{x:0,y:0}}};
			content.__drg={pos:{container:container}};
			for (var a in scrollview._scrollviewprototype)
				container[a]=scrollview._scrollviewprototype[a];
			for (var a in scrollview._scrollviewcontentprototype)
				content[a]=scrollview._scrollviewcontentprototype[a];
			for (var a=0;a<this._scrollviewevents.length;a++)
				if (container.getAttribute(this._scrollviewevents[a])) container[this._scrollviewevents[a]]=new Function(container.getAttribute(this._scrollviewevents[a]));
			this.applyTouchEvents(container,this._touchstart,this._touchmove,this._touchend);
			this.addEventListener(container,'mousewheel', scrollview._onwheel);

			this.switchbarmode(container);
			this.relayout(container);

			return content;
		}
		return null;
	},
	// UTILITY
	onTap:function(dest,touchend) {
		if (!this._hardware.touchenabled) {
			this.addEventListener(dest,"mousedown",this._disabledrag);
			this.addEventListener(dest,"mouseup",function(e){if(this.ontouchend){e.touches=[];e.mouseWrapper=true;this.ontouchend.apply(this,[e]);}});
		}
		dest.ontouchend=function(e) { if (scrollview.clickCancelled(this)) return false; else return touchend.apply(this,[e]); }
	},
	clickCancelled:function(th) {
		while (th.parentNode) {
			if (th&&(th.getAttribute&&th.getAttribute("tapdisabled")=="yes")||(th.__drg&&th.__drg.pos.drag&&th.__drg.pos.drag.drag)) return true;
			th=th.parentNode;
		}
		return false;
	},
	broadcastRelayout:function(father) {
		var containers=scrollview.getElementsByClassName(document.body,"scrollview-container");
		var contentregexp=new RegExp('\\bscrollview-content\\b');
		if (contentregexp.test(father.className)) containers.push(father);
		for (var a=0;a<containers.length;a++) containers[a].relayout(true);
	},	
	setCssDisplay:function(a,value) {
		a.style.display=value;
		if (value.toLowerCase()!="none") this.broadcastRelayout(a);
	},
	disableDrag:function(obj) {
		this.addEventListener(obj,"mousedown",this._disabledrag);
	}
}

/*scrollview.addEventListener(window,"load",scrollview.init);*/
