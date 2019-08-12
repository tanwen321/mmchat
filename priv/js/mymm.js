var lockReconnect = false;  //避免ws重复连接
var ws = null;          // 判断当前浏览器是否支持WebSocket
var wsUrl = "ws://" + location.host + "/mmchat_socket";
var hei;

// if (!window.WebSocket) {
    // alert("WebSocket not supported by this browser");
// }

function $(id) {
    return document.getElementById(id);
};

screenFuc();
function screenFuc() {
    var topHeight = $("chatBox-head").clientHeight;//聊天头部高度
    //屏幕小于768px时候,布局change
    var winWidth = window.innerWidth;
    if (winWidth <= 768) {
        var totalHeight = window.innerHeight; //页面整体高度 551
        $("chatBox").style.top="-14%";
        $("chatBox").style.height = (totalHeight - topHeight) + "px";
        $("chatBox-info").style.height = (totalHeight - topHeight) + "px";
        var infoHeight = $("chatBox-info").clientHeight;//聊天头部以下高度
        //中间内容高度
        $("mmchat").style.height = (infoHeight - 46) + "px";
        hei = (infoHeight - 46) + "px";

        $("mmgp").style.height = (totalHeight - topHeight) + "px";
        $("chatBox-kuang").style.height = (totalHeight - topHeight) + "px";
        $("div-textarea").style.width = (winWidth - 106) + "px";
    } else {
        $("chatBox").style.height = "495px";
        $("chatBox-info").style.height = "495px";
        $("mmchat").style.height = "448px";
        hei = "448px";
        $("mmgp").style.height = "495px";
        $("chatBox-kuang").style.height = "495px";
        $("div-textarea").style.width = "260px";
    }
};

window.onresize = function (){
    screenFuc();
};

function do_start_chat()
{
	start_chat(this);
	set_scroll();
}

function start_chat(obj){
    $("chatContainer").className ='chatContainer';
    $("chatBox-head-one").style.display='none';
    $("chatBox-head-two").style.display='block';
    $("mmgp").style.display='none';
    $("chatBox-kuang").style.display='block';

    var nid = obj.id.replace(/per_/,"chatBox-content-");
    $(nid).className = 'chatBox-content-demo';
    obj.getElementsByClassName("message-num")[0].innerHTML = 0;
	
    //传名字
    $("ChatInfoName").innerHTML = obj.getElementsByClassName("chat-name")[0].getElementsByTagName("p")[0].innerText;

    //传头像
    $("ChatInfoHead").getElementsByTagName('img')[0].src = obj.getElementsByTagName("div")[0].getElementsByTagName("img")[0].src;

    $(nid).style.height = hei;
};

function return_list(){
    if($("mmchat").getElementsByClassName('chatBox-content-demo').length == 1){
        $("mmchat").getElementsByClassName('chatBox-content-demo')[0].className='chatBox-content-other';
    }
    $("chatBox-head-one").style.display='block';
    $("chatBox-head-two").style.display='none';
    $("mmgp").style.display='block';
    $("chatBox-kuang").style.display='none';
};

function make_bq() {
    var flist = new Array("angel","angry","astonished-1","astonished","confused","cool-1","cool","cry-1","cry","devil","dizzy","expressionless","flushed","happy-1","happy-2","happy","injury","in-love","joy","kiss-1","kiss-2","kiss","mask","mute","neutral","sad-1","sad","scared-1","scared","secret","shocked","sick","sleeping","smile-1","smile","smiling-1","smiling","smirking","surprised","sweat","thinking","tired","tongue-1","tongue-2","tongue","unamused","vomiting-1","vomiting","wink","zombie");
    var face = document.getElementById('face');
    for(var i = 0; i < flist.length; i++) {
        var a = document.createElement("a");
        a.innerHTML = '<img class="emojiSvg" src="emoji-png/051-' + flist[i] + '.png" alt="" />';
        face.appendChild(a);
    };
}

function cop_nowtime(oid){
    var bobj = oid.replace(/chatBox-content-/,"mti_");
    var myDate = new Date();
    var ntl = new Array(5);
    ntl[0] = myDate.getFullYear();
    ntl[1] = myDate.getMonth() + 1;
    if (myDate.getMonth()<9){
        ntl[1] = "0" + (myDate.getMonth() + 1);
    }
    ntl[2] = myDate.getDate();
    if (myDate.getDate()<10){
        ntl[2] = "0" + myDate.getDate();
    }
    ntl[3] = myDate.getHours();
    if (myDate.getHours()<10){
        ntl[3] = "0" + myDate.getHours();
    } 
    ntl[4] = myDate.getMinutes();
    if (myDate.getMinutes()<10){
        ntl[4] = "0" + myDate.getMinutes();
    }
    var btl = $(bobj).innerText.split("-");
    $(bobj).innerText = ntl[0] + "-" + ntl[1] + "-" + ntl[2] + "-" + ntl[3] + "-" + ntl[4];
    if($(oid).getElementsByClassName("chat-date").length == 0){

        return  '<div class="author-name"><small class="chat-date">'+ ntl[0] + "年" + ntl[1] + "月" + ntl[2] + "日 " + ntl[3] + ":" + ntl[4] +'</small></div>';        
    }
    else{   
        var diff = (parseInt(ntl[0]) - parseInt(btl[0])) * 525600 + (parseInt(ntl[1]) - parseInt(btl[1])) * 43200 + (parseInt(ntl[2]) - parseInt(btl[2])) * 1440 + (parseInt(ntl[3]) - parseInt(btl[3])) * 60 + (parseInt(ntl[4]) - parseInt(btl[4]));
        console.log(diff);  
        if (diff > 5){
            return  '<div class="author-name"><small class="chat-date">'+ ntl[0] + "年" + ntl[1] + "月" + ntl[2] + "日 " + ntl[3] + ":" + ntl[4] +'</small></div>';
        }
        else{
            return "";
        }        
    }
};

function cop_time(oid, nt){
    var bobj = oid.replace(/chatBox-content-/,"mti_");
    var ntl = nt.split("-");
    var btl = $(bobj).innerText.split("-");
    $(bobj).innerText = nt;
    if($(oid).getElementsByClassName("chat-date").length == 0){
        return  '<div class="author-name"><small class="chat-date">'+ ntl[0] + "年" + ntl[1] + "月" + ntl[2] + "日 " + ntl[3] + ":" + ntl[4] +'</small></div>';
    }
    else{
        var diff = (parseInt(ntl[0]) - parseInt(btl[0])) * 525600 + (parseInt(ntl[1]) - parseInt(btl[1])) * 43200 + (parseInt(ntl[2]) - parseInt(btl[2])) * 1440 + (parseInt(ntl[3]) - parseInt(btl[3])) * 60 + (parseInt(ntl[4]) - parseInt(btl[4]));
        if (diff > 5){
            return  '<div class="author-name"><small class="chat-date">'+ ntl[0] + "年" + ntl[1] + "月" + ntl[2] + "日 " + ntl[3] + ":" + ntl[4] +'</small></div>';
        }
        else{
            return "";
        }        
    }

};

//      发送信息
function send_txt(){
    var textContent = $("div-textarea").innerText.replace(/[\n\r]/g, '<br>')
    if (textContent != "") {
        var mng = $("mmchat").getElementsByClassName('chatBox-content-demo')[0];
        var ng = mng.id.substring(16);
/*        var mtx = $("mytuxiang").innerText;*/
        var tx = $("mtx").getElementsByTagName("img")[0].src;
        ws.send(ng + '@1@' + textContent);
        var time_now = cop_nowtime(mng.id);
        mng.innerHTML += '<div class=\"clearfloat\">' + time_now + '<div class=\"right\"> <div class=\"chat-message\"> ' + textContent + ' </div><div class=\"chat-avatars\"><img src=\"'+ tx +'\" alt=\"头像\" /></div> </div> </div>';
        //发送后清空输入框
        $("div-textarea").innerHTML="";
        //聊天框默认最底部
        mng.scrollTop = mng.scrollHeight;
    }
};

// 查看表情
function setBiaoqing(){
    if ($("face").style.display=="block"){
        $("face").style.display = "none";
    }
    else{
        $("face").style.display = "block";
    }
};

//      发送表情
function send_bq(){
    var bq = "./emoji-png" + this.src.substring(this.src.lastIndexOf("/"));
/*    var mtx = $("mytuxiang").innerText;*/
    var tx = $("mtx").getElementsByTagName("img")[0].src;
    var mng = $("mmchat").getElementsByClassName('chatBox-content-demo')[0];
    var ng = mng.id.substring(16);
    ws.send(ng + '@2@' + bq);
    var time_now = cop_nowtime(mng.id);
    mng.innerHTML += '<div class=\"clearfloat\">' + time_now + '<div class=\"right\"> <div class=\"chat-message\"><img style="width:2em;hight:2em" src=' + bq + '></div><div class=\"chat-avatars\"><img src=\"' + tx +'\" alt=\"头像\" /></div> </div> </div>';
    setBiaoqing();

    //聊天框默认最底部
    mng.scrollTop = mng.scrollHeight;
};

function set_scroll(){
    if($("mmchat").getElementsByClassName('chatBox-content-demo').length == 1){
        var mchat = $("mmchat").getElementsByClassName('chatBox-content-demo')[0];
        mchat.scrollTop = mchat.scrollHeight;
    }
};

//      发送图片
function selectImg(pic) {
    if (!pic.files || !pic.files[0]) {
    return;
    }
    var reader = new FileReader();
    reader.onload = function (evt) {
        var images = evt.target.result;
        var mng = $("mmchat").getElementsByClassName('chatBox-content-demo')[0];
        var ng = mng.id.substring(16);
        var time_now = cop_nowtime(mng.id);
        var tx = $("mtx").getElementsByTagName("img")[0].src;
        ws.send(ng + '@3@' + images);
        mng.innerHTML += '<div class="clearfloat">' + time_now + '<div class="right"> <div class="chat-message"><img src=' + images + '></div> <div class="chat-avatars"><img src="' + tx + '" alt="头像" /></div> </div> </div>';
        //聊天框默认最底部
        mng.scrollTop = mng.scrollHeight;
    };
    reader.readAsDataURL(pic.files[0]);
    $("inputImage").value="";
};

function init_group(buf){
    if (buf.gr.length==1){
        if ($("per_"+ buf.gr[0].id) == undefined){
            $("mmgp").innerHTML += '<div id="per_'+ buf.gr[0].id +'" class="chat-list-people" οnclick="start_chat(this);"><div><img src="'+ buf.gr[0].im +'" alt="头像"/></div><div class="chat-name" οnclick="alert(\'this a test\')"><p>'+ buf.gr[0].na +'</p></div><div class="message-num">0</div></div>';
            $("mmchat").innerHTML += '<div class="chatBox-content-other" id="chatBox-content-'+ buf.gr[0].id +'"><div id="mti_' + buf.gr[0].id +'" style="display:none;">' + buf.gr[0].ti + '</div></div>';     
        }
		else{
			$("per_"+ buf.gr[0].id).style.display="block";
//			$("chatBox-content-"+ buf.gr[0].id).style.display="block";
		}
    }
    else{
        var i;
        $("mtx").getElementsByTagName("img")[0].src = buf.gr[0].im;
/*        $("mytuxiang").innerHTML = buf.gr[0].im;*/
        for(i=1; i<buf.gr.length; ++i){
			if ($("per_"+ buf.gr[i].id) == undefined){
				$("mmgp").innerHTML += '<div id="per_'+ buf.gr[i].id +'" class="chat-list-people" οnclick="start_chat(this);"><div><img src="'+ buf.gr[i].im +'" alt="头像"/></div><div class="chat-name" οnclick="alert(\'this a test\')"><p>'+ buf.gr[i].na +'</p></div><div class="message-num">0</div></div>';
				$("mmchat").innerHTML += '<div class="chatBox-content-other" id="chatBox-content-'+ buf.gr[i].id +'"><div id="mti_' + buf.gr[i].id +'" style="display:none;">' + buf.gr[i].ti + '</div></div>';
			}
			else{
				$("per_"+ buf.gr[0].id).style.display="block";
//				$("chatBox-content-"+ buf.gr[0].id).style.display="block";
			}
        }
    }
};

function add_ev(){
    var friends = {
      all: document.querySelectorAll('.chat-list-people')};

    friends.all.forEach(function (f) {
	  f.removeEventListener('mousedown', do_start_chat, false);
      f.addEventListener('mousedown', do_start_chat, false);        
    });
};

function add_bq_ev(){
    var biaoqs = {
      all: document.querySelectorAll('.emojiSvg')};
	
    biaoqs.all.forEach(function (f) {
	  f.removeEventListener('click', send_bq, false);	
      f.addEventListener('click', send_bq, false);
    });	
};

//  websocket连接
function go() {
	createWebSocket(wsUrl);
}

function handMsg(edata){
	if(edata != "pong"){
        if (edata == "wrong"){
            self.location='./index.html';
        }
        else{
            var buf=JSON.parse(edata);
            if(buf.gr == undefined){
                if(buf.fe == undefined){
                    var mid = "chatBox-content-" + buf.id;
                    var mnum = $("per_" + buf.id).getElementsByClassName("message-num")[0];
                    var time_now = cop_time(mid, buf.ti);
                    mnum.innerHTML = parseInt(mnum.innerText) + 1;
                    if(buf.ty == '1'){
                        $(mid).innerHTML += '<div class="clearfloat">' + time_now +'<div class="author-name"></div><div class="left"><div class="chat-avatars"><img src="'+ buf.fi +'" alt="头像"/></div><div class="chat-message">'+ buf.da +'</div></div></div>';
                        set_scroll();
                    }
                    else if (buf.ty == '2'){
                        $(mid).innerHTML += '<div class="clearfloat">' + time_now +'<div class="author-name"></div><div class="left"><div class="chat-avatars"><img src="'+ buf.fi +'" alt="头像"/></div><div class="chat-message"><img style="width:2em;hight:2em" src="'+ buf.da +'" alt=""></div></div></div>';
                        set_scroll();
                    }
                    else{
                        $(mid).innerHTML += '<div class="clearfloat">' + time_now +'<div class="author-name"></div><div class="left"><div class="chat-avatars"><img src="'+ buf.fi +'" alt="头像"/></div><div class="chat-message"><img src="'+ buf.da +'" alt=""></div></div></div>';
                        set_scroll();
                    }                
                }
                else{
    				return_list();
                    var fep = "per_" + buf.fe;
    //                var fec = "chatBox-content-" + buf.fe;
    				$(fep).style.display='none';
    //				$(fec).style.display='none';
                    // $(fep).parentNode.removeChild($(fep));
                    // $(fec).parentNode.removeChild($(fec));
                }
            }
            else{
                init_group(buf);
                add_ev();
            }}
    }};

// websocket断线重连
function createWebSocket(url) {
	try {
		if ('WebSocket' in window) {
			ws = new WebSocket(url);
		} else if ('MozWebSocket' in window) {
			ws = new MozWebSocket(url);
		} else {
			alert("您的浏览器不支持websocket协议,建议使用新版谷歌、火狐等浏览器，请勿使用IE10以下浏览器，360浏览器请使用极速模式，不要使用兼容模式！");
		}
		initEventHandle();
	} catch (e) {
		reconnect(url);
//		console.log(e);
	}
}

function initEventHandle() {
	ws.onclose = function () {
        $("mtx").style.filter="grayscale(100%)";
//		console.log("llws连接关闭!" + new Date().toUTCString());
		reconnect(wsUrl);
	};
	ws.onerror = function () {
        $("mtx").style.filter="grayscale(100%)";
//		console.log("llws连接错误!");
		reconnect(wsUrl);
	};
	ws.onopen = function () {
        $("mtx").style.filter="";
		make_bq();
        add_bq_ev();
		heartCheck.reset().start();
//		console.log("llws连接成功!" + new Date().toUTCString());
	};
	ws.onmessage = function (event) {
		heartCheck.reset().start();
		var eventData = event.data;
		handMsg(eventData);
	};
}

window.onbeforeunload = function () {
	ws.close();
}

function reconnect(url) {
	if (lockReconnect) return;
	lockReconnect = true;
	setTimeout(function () {
	createWebSocket(url);
	lockReconnect = false;
	}, 2000);
}

//心跳检测
var heartCheck = {
	timeout: 10000,		//10秒
	timeoutObj: null,
	serverTimeoutObj: null,
	reset: function () {
		clearTimeout(this.timeoutObj);
		clearTimeout(this.serverTimeoutObj);
		return this;
	},
	start: function () {
		var self = this;
		this.timeoutObj = setTimeout(function () {
			ws.send("ping");
			console.log("ping!")
			self.serverTimeoutObj = setTimeout(function () {
				ws.close();     
			},self.timeout)
		},this.timeout)
	}
}


window.onload=go();
