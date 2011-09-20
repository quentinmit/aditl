// ---
// Copyright (c) 2011 Francesco Cottone, http://www.kesiev.com/
// ---
/*
	These are some little Javascript snippets for doing some common GUI tasks, like item selection,
	getting DOM elements etc. Can help you on adding some interactivity to VanillaOS demos but
	don't abuse - at least, in demos! You can use them also for your full working webapplication :)
*/
var vos={
	$:function(id) {
		return document.getElementById(id);
	},
	create:function(data,to) {
		var obj;
		if (data.text) obj=document.createTextNode(data.text); else obj=document.createElement(data.type);
		if (data.style) for (var a in data.style) obj.style[a]=data.style[a];
		if (data.attributes) for (var a in data.attributes) obj.setAttribute(a,data.attributes[a]);
		if (data.properties) for (var a in data.properties) obj[a]=data.properties[a];
		if (data.childs) for (var a=0;a<data.childs.length;a++) this.create(data.childs[a],obj);
		if (data.ontap) scrollview.onTap(obj,data.ontap);
		if (to) to.appendChild(obj);
		return obj;
	},
	select:function(row,classname) {
		var reg = new RegExp('\\b'+classname+'\\b');
		var nodes=row.parentNode.childNodes;
		for (var a=0;a<nodes.length;a++) {
			if (nodes[a]&&nodes[a].className)
				nodes[a].className=nodes[a].className.replace(reg,"");
			if (nodes[a]==row)
				nodes[a].className+=" "+classname;
		}
	},
	getNext:function(from,parentmode,classname) {
		var reg = new RegExp('\\b'+classname+'\\b');
		while (from[parentmode]) {
			from=from[parentmode];
			if (from.className&&from.className.match(reg)) return from;
		}
		return null;
	},
	_clearpassive:function() {
		document.body.removeChild(this._passive.obj);
	},
	passive:function(text) {
		if (!this._passive) {
			this._passive={obj:document.createElement("div")};
			this._passive.obj.className="vos-passive-popup";
		}
		this._passive.obj.innerHTML=text;
		if (this._passive.timer) clearTimeout(this._passive.timer);
		if (!this._passive.obj.parentNode) document.body.appendChild(this._passive.obj);
		var self=this;
		this._passive.timer=setTimeout(function(){self._clearpassive()},3000);
	}
}