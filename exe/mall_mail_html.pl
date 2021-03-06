﻿# mall_mail_html.pl
# author:T.Hashiguchi
# date:2015/04/21

#========== 改訂履歴 ==========
#
########################################################

#/usr/bin/perl

use strict;
use warnings;
use Cwd;
use Encode;
use File::Path;
use LWP::UserAgent;
use LWP::Simple;
use HTML::TreeBuilder;

####################
##　ログファイル
####################
# ログファイルを格納するフォルダ名
my $output_log_dir="./../log";
# ログフォルダが存在しない場合は作成
unless (-d $output_log_dir) {
	if (!mkdir $output_log_dir) {
		&output_log("ERROR!!($!) create $output_log_dir failed\n");
		exit 1;
	}
}
#　ログファイル名
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time());
my $time_str = sprintf("%04d%02d%02d%02d%02d%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec);
my $log_file_name="$output_log_dir"."/"."create_mall_entry_data"."$time_str".".log";
# ログファイルのオープン
if(!open(LOG_FILE, "> $log_file_name")) {
	print "ERROR!!($!) $log_file_name open failed.\n";
	exit 1;
}

####################
##　出力ファイルのオープン
####################
#出力ディレクトリ
my $output_up_data_dir="../up_data";
#出力ファイル名
my $output_file_name_time= sprintf("%04d%02d%02d", $year + 1900, $mon + 1,$mday);
my $output_file_rakuten_name="$output_up_data_dir"."/".$output_file_name_time."_rakuten".".html";
my $output_file_yahoo_name="$output_up_data_dir"."/".$output_file_name_time."_yahoo".".html";

#出力先ディレクトリの作成
unless(-d $output_up_data_dir) {
	# 存在しない場合はフォルダ作成
	if(!mkpath($output_up_data_dir)) {
		output_log("ERROR!!($!) $output_up_data_dir create failed.");
		exit 1;
	}
}

#出力ファイルのオープン
my $output_rhtml_file_disc;
my $output_yhtml_file_disc;
if (!open $output_rhtml_file_disc, ">", $output_file_rakuten_name) {
	&output_log("ERROR!!($!) $output_file_rakuten_name open failed.");
	exit 1;
}
if (!open $output_yhtml_file_disc, ">", $output_file_yahoo_name) {
	&output_log("ERROR!!($!) $output_file_yahoo_name open failed.");
	exit 1;
}
####################
## HTMLの取得
####################

####### 楽天 #######

# 楽天の新着URL
my $rakuten_new_url = 'http://www.rakuten.ne.jp/gold/hff/hitoke/newitem20.html';
# 楽天の再入荷URL
my $rakuten_renew_url = 'http://www.rakuten.ne.jp/gold/hff/hitoke/renewitem20.html';
# 楽天のランキングURL
my $rakuten_ranking_url = 'http://www.rakuten.ne.jp/gold/hff/hitoke/ranking.html';

# HTMLを取得
# LWP::Simpleの「get」関数を使用                                                
# 楽天店の新着HTML取得
my $rakuten_new = get($rakuten_new_url) or die "Couldn't get it!";
$rakuten_new = Encode::encode('Shift_JIS', $rakuten_new);
# 楽天店の再入荷HTML取得
my $rakuten_renew = get($rakuten_renew_url) or die "Couldn't get it!";
$rakuten_renew = Encode::encode('Shift_JIS', $rakuten_renew);
# 楽天店のランキングHTML取得
my $rakuten_ranking = get($rakuten_ranking_url) or die "Couldn't get it!";
$rakuten_ranking = Encode::encode('Shift_JIS', $rakuten_ranking);

####### ヤフー #######

# ヤフーの新着URL
my $yahoo_new_url = 'http://shopping.geocities.jp/hff/hitoke/newitem.html';
# ヤフーの再入荷URL
my $yahoo_renew_url = 'http://shopping.geocities.jp/hff/hitoke/renewitem.html';

# HTMLを取得
# LWP::Simpleの「get」関数を使用                                                
# ヤフー店の新着HTML取得
my $yahoo_new = get($yahoo_new_url) or die "Couldn't get it!";
$yahoo_new = Encode::encode('Shift_JIS', $yahoo_new);
# ヤフー店の再入荷HTML取得
my $yahoo_renew = get($yahoo_renew_url) or die "Couldn't get it!";
$yahoo_renew = Encode::encode('Shift_JIS', $yahoo_renew);

# print $yahoo_new."\n";
# print $yahoo_renew."\n";

####################
## 楽天店のHTMLの中の要素取得
####################

####### 楽天 #######

## 新着商品 ##

my $tree_new = HTML::TreeBuilder->new;
$tree_new->parse($rakuten_new);
# ブランドのリストを作成する
my @new_brand_list_place = $tree_new->look_down('class', 'itemTitle');
my @new_brand_list =();
for my $brand_li (@new_brand_list_place) {
     push(@new_brand_list,$brand_li->as_text);
}

# アイテム名のリストを作成する
my @new_item_list_place =  $tree_new->look_down('class', 'itemText');
my @new_item_list = ();
for my $item_li (@new_item_list_place) {
    push (@new_item_list,$item_li->as_text);
}

# リンクのリストを作成する
my @new_link_list_place =  $tree_new->find('a');
my @new_link_list = ();
for my $link (@new_link_list_place) {
    push (@new_link_list,$link->attr('href'));
}

# 画像のリストを作成する
my @new_img_url_list_place =  $tree_new->look_down('class', 'itemsA clearfix')->find('img');
my @new_img_url_list =();
for my $img_li (@new_img_url_list_place) {
    my $img_src = "";
    $img_src = $img_li->attr('src');
    $img_src =~ s/thumbnail.//g;
    $img_src =~ s/\/\@0_mall//g;
    $img_src =~ s/\?_ex=142x142//g;
    push (@new_img_url_list,$img_src);
}
## 再入荷商品 ##
my $tree_renew = HTML::TreeBuilder->new;
$tree_renew->parse($rakuten_renew);
# ブランドのリストを作成する
my @renew_brand_list_place = $tree_renew->look_down('class', 'itemTitle');
my @renew_brand_list =();
for my $brand_li (@renew_brand_list_place) {
     push(@renew_brand_list,$brand_li->as_text);
}

# アイテム名のリストを作成する
my @renew_item_list_place =  $tree_renew->look_down('class', 'itemText');
my @renew_item_list = ();
for my $item_li (@renew_item_list_place) {
    push (@renew_item_list,$item_li->as_text);
}

# リンクのリストを作成する
my @renew_link_list_place =  $tree_renew->find('a');
my @renew_link_list = ();
for my $link (@renew_link_list_place) {
    push (@renew_link_list,$link->attr('href'));
}

# 画像のリストを作成する
my @renew_img_url_list_place =  $tree_renew->look_down('class', 'itemsA clearfix')->find('img');
my @renew_img_url_list =();
for my $img_li (@renew_img_url_list_place) {
    my $img_src = "";
    $img_src = $img_li->attr('src');
    $img_src =~ s/thumbnail.//g;
    $img_src =~ s/\/\@0_mall//g;
    $img_src =~ s/\?_ex=142x142//g;
    push (@renew_img_url_list,$img_src);
}

## ランキング商品 ##
my $tree_ranking = HTML::TreeBuilder->new;
$tree_ranking->parse($rakuten_ranking);
# ブランドのリストを作成する
my @ranking_brand_list_place = $tree_ranking->look_down('class', 'itemTitle');
my @ranking_brand_list =();
for my $brand_li (@ranking_brand_list_place) {
     push(@ranking_brand_list,$brand_li->as_text);
}

# アイテム名のリストを作成する
my @ranking_item_list_place =  $tree_ranking->look_down('class', 'itemText');
my @ranking_item_list = ();
for my $item_li (@ranking_item_list_place) {
    push (@ranking_item_list,$item_li->as_text);
}

# リンクのリストを作成する
my @ranking_link_list_place =  $tree_ranking->find('a');
my @ranking_link_list = ();
for my $link (@ranking_link_list_place) {
    push (@ranking_link_list,$link->attr('href'));
}

# 画像のリストを作成する
my @ranking_img_url_list_place = $tree_ranking->look_down('class', 'itemsA clearfix')->find('img');
my @ranking_img_url_list =();
my $img_list_count = @ranking_img_url_list_place;
for my $img_li (@ranking_img_url_list_place) {
    my $img_src = "";
    $img_src = $img_li->attr('src');
    if($img_src =~ /ranking/){
	next;
    }
    else {
	    $img_src =~ s/thumbnail.//g;
	    $img_src =~ s/\/\@0_mall//g;
	    $img_src =~ s/\?_ex=142x142//g;
	    push (@ranking_img_url_list,$img_src);
    }
}

####################
## ヤフー店のHTMLの中の要素取得
####################

####### ヤフー #######

## 新着商品 ##

my $tree_new_y = HTML::TreeBuilder->new;
$tree_new_y->parse($yahoo_new);
# ブランドのリストを作成する
my @new_brand_list_place_y = $tree_new_y->look_down('class', 'itemTitle');
my @new_brand_list_y =();
for my $brand_li (@new_brand_list_place_y) {
     push(@new_brand_list_y,$brand_li->as_text);
}

# アイテム名のリストを作成する
my @new_item_list_place_y =  $tree_new_y->look_down('class', 'itemText');
my @new_item_list_y = ();
for my $item_li (@new_item_list_place_y) {
    push (@new_item_list_y,$item_li->as_text);
}

# リンクのリストを作成する
my @new_link_list_place_y =  $tree_new_y->find('a');
my @new_link_list_y = ();
for my $link (@new_link_list_place_y) {
    push (@new_link_list_y,$link->attr('href'));
}

# 画像のリストを作成する
my @new_img_url_list_place_y =  $tree_new_y->look_down('class', 'itemsA clearfix')->find('img');
my @new_img_url_list_y =();
for my $img_li (@new_img_url_list_place_y) {
    my $img_src = "";
    $img_src = $img_li->attr('src');
    $img_src =~ s/thumbnail.//g;
    $img_src =~ s/\/\@0_mall//g;
    $img_src =~ s/\?_ex=142x142//g;
    push (@new_img_url_list_y,$img_src);
}
## 再入荷商品 ##
my $tree_renew_y = HTML::TreeBuilder->new;
$tree_renew_y->parse($yahoo_renew);
# ブランドのリストを作成する
my @renew_brand_list_place_y = $tree_renew_y->look_down('class', 'itemTitle');
my @renew_brand_list_y =();
for my $brand_li (@renew_brand_list_place_y) {
     push(@renew_brand_list_y,$brand_li->as_text);
}

# アイテム名のリストを作成する
my @renew_item_list_place_y =  $tree_renew_y->look_down('class', 'itemText');
my @renew_item_list_y = ();
for my $item_li (@renew_item_list_place_y) {
    push (@renew_item_list_y,$item_li->as_text);
}

# リンクのリストを作成する
my @renew_link_list_place_y =  $tree_renew_y->find('a');
my @renew_link_list_y = ();
for my $link (@renew_link_list_place_y) {
    push (@renew_link_list_y,$link->attr('href'));
}

# 画像のリストを作成する
my @renew_img_url_list_place_y =  $tree_renew_y->look_down('class', 'itemsA clearfix')->find('img');
my @renew_img_url_list_y =();
for my $img_li (@renew_img_url_list_place_y) {
    my $img_src = "";
    $img_src = $img_li->attr('src');
    $img_src =~ s/thumbnail.//g;
    $img_src =~ s/\/\@0_mall//g;
    $img_src =~ s/\?_ex=142x142//g;
    push (@renew_img_url_list_y,$img_src);
}

####################
## 楽天店のHTMLの作成
####################

# 楽天店用のHTML
my $rakuten_html ="";
# HTMLのヘッダー・共通部分
my $rakuten_html_header = 
<<"HTML_STR_1";
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-2022-jp" />
<title>ハイ・ファッション・ファクトリー</title>
</head>
<body>
<div align="center">
<a href="http://www.rakuten.ne.jp/gold/hff/" target="_blank"><img src="http://image.rakuten.co.jp/hff/cabinet/mail/mailmagazine_header2.gif" alt="HIGH FASHION FACTORY" border="0" width="100%"></a>
<!-- バナー×２ start-->
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td width="50%">
<a href="http://item.rakuten.co.jp/hff/c/0000000591/" target="_blank"><img src="http://image.rakuten.co.jp/hff/cabinet/mail/150411/tagliatore_150324.jpg" alt="" width="100%" border="0"></a>
</td>
<td width="50%">
<a href="http://item.rakuten.co.jp/hff/c/0000000486/" target="_blank"><img src="http://image.rakuten.co.jp/hff/cabinet/mail/150411/lardini_150324.jpg" alt="" width="100%" border="0"></a>
</td>
</tr>
</table>
<!-- バナー×２ end-->
<!-- 新着商品 start-->
HTML_STR_1
	Encode::from_to( $rakuten_html_header, 'utf8', 'shiftjis' );
	# HTMLのヘッダーを追加
	$rakuten_html .= $rakuten_html_header;
# 新着商品スタート
my $rakuten_newitem_banner =
<<"HTML_STR_2";
<br>
<img src="http://image.rakuten.co.jp/hff/cabinet/mail/mailmagazine_new3.gif" alt="新着商品" width="100%">
<table width="100%" border="0" cellspacing="0" cellpadding="0">
HTML_STR_2
Encode::from_to( $rakuten_newitem_banner, 'utf8', 'shiftjis' );
	my $table_new_item ="";
	$table_new_item .= $rakuten_newitem_banner;
	for(my $i=0; $i<=8; $i++) {
		# 大枠tableの行挿入
		if($i%3 == 0){
			$table_new_item .="<tr valign=\"top\">\n";
		}
		my $header ="<td width=\"32%\">\n<table width=\"100%\" cellpadding=\"0\" cellspacing=\"1\">\n";
		# 最初の3つのtdのみ<td width="32%">
		if($i>=3){
			$header ="<td>\n<table width=\"100%\" cellpadding=\"0\" cellspacing=\"1\">\n";
		}
		my $mon_h = $mon+1;
		my $tr_day = "<tr>\n<td height=\"19\" align=\"center\" bgcolor=\"#EEEEEE\"><font size=\"4\">$mon_h月$mday日</font></td>\n</tr>\n";
		Encode::from_to( $tr_day, 'utf8', 'shiftjis' );
		my $tr_td_link ="<tr>\n<td align=\"center\"><a href=\"$new_link_list[$i]\" target=\"_blank\">\n";
		my $tr_td_img ="<img src=\"$new_img_url_list[$i]\" border=\"0\" width=\"100%\"></a></td>\n</tr>\n";
		my $tr_brand ="<tr>\n<td colspan=\"2\" align=\"center\"><font size=\"3\" color=\"#7E6E4D\">$new_brand_list[$i]</font></td>\n</tr>\n";
		my $tr_name ="<tr>\n<td align=\"left\"><a href=\"$new_link_list[$i]\" target=\"_blank\"><font size=\"3\" color=\"#202020\">$new_item_list[$i]</font></a></td>\n</tr>\n</table>\n</td>\n";
		$table_new_item .=$header.$tr_day.$tr_td_link.$tr_td_img.$tr_brand.$tr_name;
		if($i%3 == 2){
			$table_new_item .= "</tr>\n\n<tr>\n<td colspan=\"3\">\n<img src=\"http://image.rakuten.co.jp/hff/cabinet/mail/s.gif\" alt=\"\" width=\"1\" height=\"15\">\n</td>\n</tr>";
		}
	}
# 新着商品エンド
my $rakuten_newitem_footer =
<<"HTML_STR_3";
</table>
<!-- 新着商品 end-->
HTML_STR_3
Encode::from_to( $rakuten_newitem_footer, 'utf8', 'shiftjis' );
	$table_new_item .= $rakuten_newitem_footer;
	# 新着エリアをHTMLに追加
	$rakuten_html .= $table_new_item;

# 再入荷商品スタート
my $rakuten_renewitem_banner =
<<"HTML_STR_4";
<!-- 再入荷商品 start-->
<img src="http://image.rakuten.co.jp/hff/cabinet/mail/mailmagazine_re.gif" alt="再入荷商品" width="100%">
<table width="100%" border="0" cellspacing="0" cellpadding="0">
HTML_STR_4
Encode::from_to( $rakuten_renewitem_banner, 'utf8', 'shiftjis' );
	my $table_renew_item ="";
	$table_renew_item .= $rakuten_renewitem_banner;
	for(my $i=0; $i<=5; $i++) {
		# 大枠tableの行挿入
		if($i%3 == 0){
			$table_renew_item .="<tr valign=\"top\">\n";
		}
		my $header ="<td width=\"32%\">\n<table width=\"100%\" cellpadding=\"0\" cellspacing=\"1\">\n";
		# 最初の3つのtdのみ<td width="32%">
		if($i>=3){
			$header ="<td>\n<table width=\"100%\" cellpadding=\"0\" cellspacing=\"1\">\n";
		}
		my $mon_h = $mon+1;
		my $tr_day = "<tr>\n<td height=\"19\" align=\"center\" bgcolor=\"#EEEEEE\"><font size=\"4\">$mon_h月$mday日</font></td>\n</tr>\n";
		Encode::from_to( $tr_day, 'utf8', 'shiftjis' );
		my $tr_td_link ="<tr>\n<td align=\"center\"><a href=\"$renew_link_list[$i]\" target=\"_blank\">\n";
		my $tr_td_img ="<img src=\"$renew_img_url_list[$i]\" border=\"0\" width=\"100%\"></a></td>\n</tr>\n";
		my $tr_brand ="<tr>\n<td colspan=\"2\" align=\"center\"><font size=\"3\" color=\"#7E6E4D\">$renew_brand_list[$i]</font></td>\n</tr>\n";
		my $tr_name ="<tr>\n<td align=\"left\"><a href=\"$renew_link_list[$i]\" target=\"_blank\"><font size=\"3\" color=\"#202020\">$renew_item_list[$i]</font></a></td>\n</tr>\n</table>\n</td>\n";
		$table_renew_item .=$header.$tr_day.$tr_td_link.$tr_td_img.$tr_brand.$tr_name;
		if($i%3 == 2){
			$table_renew_item .= "</tr>\n\n<tr>\n<td colspan=\"3\">\n<img src=\"http://image.rakuten.co.jp/hff/cabinet/mail/s.gif\" alt=\"\" width=\"1\" height=\"15\">\n</td>\n</tr>\n";
		}
	}
# 再入荷商品エンド
my $rakuten_renewitem_footer =
<<"HTML_STR_3";
</table>
<!-- 再入荷商品 end-->
HTML_STR_3
Encode::from_to( $rakuten_renewitem_footer, 'utf8', 'shiftjis' );
	$table_renew_item .= $rakuten_renewitem_footer;
	# 再入荷エリアをHTMLに追加
	$rakuten_html .= $table_renew_item;

# ランキング商品スタート
my $rakuten_ranking_banner =
<<"HTML_STR_4";
<!-- ランキング start-->
<img src="http://image.rakuten.co.jp/hff/cabinet/mail/mailmagazine_ranking.gif" alt="ランキング" width="100%">
<table width="100%" border="0" cellspacing="0" cellpadding="0">
HTML_STR_4
Encode::from_to( $rakuten_ranking_banner, 'utf8', 'shiftjis' );
	my $table_ranking_item ="";
	$table_ranking_item .= $rakuten_ranking_banner;
	for(my $i=0; $i<=2; $i++) {
		# 大枠tableの行挿入
		if($i%3 == 0){
			$table_ranking_item .="<tr valign=\"top\">\n";
		}
		my $rank_num = $i+1;
		my $header ="<td width=\"32%\">\n<table width=\"100%\" cellpadding=\"0\" cellspacing=\"1\">\n";
		my $tr_rank_img = "<tr>\n<td align=\"center\">\n<img src=\"http://image.rakuten.co.jp/hff/cabinet/mail/rank_0$rank_num.gif\">\n</td>\n</tr>\n";
		my $tr_td_link ="<tr>\n<td align=\"center\"><a href=\"$ranking_link_list[$i]\" target=\"_blank\">\n";
		my $tr_td_img ="<img src=\"$ranking_img_url_list[$i]\" border=\"0\" width=\"100%\"></a></td>\n</tr>\n";
		my $tr_brand ="<tr>\n<td colspan=\"2\" align=\"center\"><font size=\"3\" color=\"#7E6E4D\">$ranking_brand_list[$i]</font></td>\n</tr>\n";
		my $tr_name ="<tr>\n<td align=\"left\"><a href=\"$ranking_link_list[$i]\" target=\"_blank\"><font size=\"3\" color=\"#202020\">$ranking_item_list[$i]</font></a></td>\n</tr>\n</table>\n</td>\n";
		$table_ranking_item .=$header.$tr_rank_img.$tr_td_link.$tr_td_img.$tr_brand.$tr_name;
		if($i%3 == 2){
			$table_ranking_item .= "</tr>\n\n<tr>\n<td colspan=\"3\">\n<img src=\"http://image.rakuten.co.jp/hff/cabinet/mail/s.gif\" alt=\"\" width=\"1\" height=\"15\">\n</td>\n</tr>\n";
		}
	}
# ランキング商品エンド
my $rakuten_ranking_item_footer =
<<"HTML_STR_5";
</table>
<!-- ランキング end-->
HTML_STR_5
Encode::from_to( $rakuten_ranking_item_footer, 'utf8', 'shiftjis' );
	$table_ranking_item .= $rakuten_ranking_item_footer;
	# ランキングエリアをHTMLに追加
	$rakuten_html .= $table_ranking_item;

# フッター
my $rakuten_footer =
<<"HTML_STR_5";
<!-- フッター start-->
<table width="96%" bgcolor="#000000" cellpadding="0" cellspacing="0">
<tr>
<td align="center" height="30" valign="middle">
<p><font color="#ffffff" size="1">
Copyright &copy; Newgene Ltd. All Rights Reserved.</font></p>
</td>
</tr>
</table>
<!-- フッター end -->
</div>
</body>
</html>
HTML_STR_5
Encode::from_to($rakuten_footer, 'utf8', 'shiftjis');
	# フッターをHTMLに追加
	$rakuten_html .= $rakuten_footer;
	# HTMLファイルに書き込み
	print $output_rhtml_file_disc $rakuten_html;
	close $output_rhtml_file_disc;
	
####################
## ヤフー店のHTMLの作成
####################

# ヤフー店用のHTML
my $yahoo_html ="";
# HTMLのヘッダー・共通部分
my $yahoo_html_header = 
<<"HTML_STR_1";
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-2022-jp" />
<title>ハイ・ファッション・ファクトリー</title>
</head>
<body>
<div align="center">
<a href="http://store.shopping.yahoo.co.jp/hff/" target="_blank"><img src="http://shopping.geocities.jp/hff/img/mail/mailmagazine_header.gif" alt="HIGH FASHION FACTORY" border="0" width="100%"/></a>
<!-- バナー×２ start-->
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td width="50%">
<a href="http://store.shopping.yahoo.co.jp/hff/cj.html" target="_blank"><img src="http://shopping.geocities.jp/hff/img/home/crocket_150324.jpg" alt="" width="100%" border="0"></a>
</td>
<td width="50%">
<a href="http://store.shopping.yahoo.co.jp/hff/pell.html" target="_blank"><img src="http://shopping.geocities.jp/hff/img/home/pelle_150324_2.jpg" alt="" width="100%" border="0"></a>
</td>
</tr>
</table>
<!-- バナー×２ end-->
<!-- 新着商品 start-->
HTML_STR_1
	Encode::from_to( $yahoo_html_header, 'utf8', 'shiftjis' );
	# HTMLのヘッダーを追加
	$yahoo_html .= $yahoo_html_header;
# 新着商品スタート
my $yahoo_newitem_banner =
<<"HTML_STR_2";
<br>
<img src="http://shopping.geocities.jp/hff/img/mail/mailmagazine_new.gif" alt="新着商品" width="100%">
<table width="100%" border="0" cellspacing="0" cellpadding="0">
HTML_STR_2
Encode::from_to( $yahoo_newitem_banner, 'utf8', 'shiftjis' );
	my $table_new_item_y ="";
	$table_new_item_y .= $yahoo_newitem_banner;
	for(my $i=0; $i<=8; $i++) {
		# 大枠tableの行挿入
		if($i%3 == 0){
			$table_new_item_y .="<tr valign=\"top\">\n";
		}
		my $header ="<td width=\"32%\">\n<table width=\"100%\" cellpadding=\"0\" cellspacing=\"1\">\n";
		# 最初の3つのtdのみ<td width="32%">
		if($i>=3){
			$header ="<td>\n<table width=\"100%\" cellpadding=\"0\" cellspacing=\"1\">\n";
		}
		my $mon_h = $mon+1;
		my $tr_day = "<tr>\n<td height=\"19\" align=\"center\" bgcolor=\"#EEEEEE\"><font size=\"4\">$mon_h月$mday日</font></td>\n</tr>\n";
		Encode::from_to( $tr_day, 'utf8', 'shiftjis' );
		my $tr_td_link ="<tr>\n<td align=\"center\"><a href=\"$new_link_list_y[$i]\" target=\"_blank\">\n";
		my $tr_td_img ="<img src=\"$new_img_url_list_y[$i]\" border=\"0\" width=\"100%\"></a></td>\n</tr>\n";
		my $tr_brand ="<tr>\n<td colspan=\"2\" align=\"center\"><font size=\"3\" color=\"#7E6E4D\">$new_brand_list_y[$i]</font></td>\n</tr>\n";
		my $tr_name ="<tr>\n<td align=\"left\"><a href=\"$new_link_list_y[$i]\" target=\"_blank\"><font size=\"3\" color=\"#202020\">$new_item_list_y[$i]</font></a></td>\n</tr>\n</table>\n</td>\n";
		$table_new_item_y .=$header.$tr_day.$tr_td_link.$tr_td_img.$tr_brand.$tr_name;
		if($i%3 == 2){
			$table_new_item_y .= "</tr>\n\n<tr>\n<td colspan=\"6\">\n<img src=\"http://shopping.geocities.jp/hff/img/mail/s.gif\" alt=\"\" width=\"1\" height=\"15\">\n</td>\n</tr>";
		}
	}
# 新着商品エンド
my $yahoo_newitem_footer =
<<"HTML_STR_3";
</table>
<!-- 新着商品 end-->
HTML_STR_3
Encode::from_to( $yahoo_newitem_footer, 'utf8', 'shiftjis' );
	$table_new_item_y .= $yahoo_newitem_footer;
	# 新着エリアをHTMLに追加
	$yahoo_html .= $table_new_item_y;

# 再入荷商品スタート
my $yahoo_renewitem_banner =
<<"HTML_STR_4";
<!-- 再入荷商品 start-->
<img src="http://shopping.geocities.jp/hff/img/mail/mailmagazine_re.gif" alt="再入荷商品" width="100%">
<table width="100%" border="0" cellspacing="0" cellpadding="0">
HTML_STR_4
Encode::from_to( $yahoo_renewitem_banner, 'utf8', 'shiftjis' );
	my $table_renew_item_y ="";
	$table_renew_item_y .= $yahoo_renewitem_banner;
	for(my $i=0; $i<=5; $i++) {
		# 大枠tableの行挿入
		if($i%3 == 0){
			$table_renew_item_y .="<tr valign=\"top\">\n";
		}
		my $header ="<td width=\"32%\">\n<table width=\"100%\" cellpadding=\"0\" cellspacing=\"1\">\n";
		# 最初の3つのtdのみ<td width="32%">
		if($i>=3){
			$header ="<td>\n<table width=\"100%\" cellpadding=\"0\" cellspacing=\"1\">\n";
		}
		my $mon_h = $mon+1;
		my $tr_day = "<tr>\n<td height=\"19\" align=\"center\" bgcolor=\"#EEEEEE\"><font size=\"4\">$mon_h月$mday日</font></td>\n</tr>\n";
		Encode::from_to( $tr_day, 'utf8', 'shiftjis' );
		my $tr_td_link ="<tr>\n<td align=\"center\"><a href=\"$renew_link_list_y[$i]\" target=\"_blank\">\n";
		my $tr_td_img ="<img src=\"$renew_img_url_list_y[$i]\" border=\"0\" width=\"100%\"></a></td>\n</tr>\n";
		my $tr_brand ="<tr>\n<td colspan=\"2\" align=\"center\"><font size=\"3\" color=\"#7E6E4D\">$renew_brand_list_y[$i]</font></td>\n</tr>\n";
		my $tr_name ="<tr>\n<td align=\"left\"><a href=\"$renew_link_list_y[$i]\" target=\"_blank\"><font size=\"3\" color=\"#202020\">$renew_item_list_y[$i]</font></a></td>\n</tr>\n</table>\n</td>\n";
		$table_renew_item_y .=$header.$tr_day.$tr_td_link.$tr_td_img.$tr_brand.$tr_name;
		if($i%3 == 2){
			$table_renew_item_y .= "</tr>\n\n<tr>\n<td colspan=\"3\">\n<img src=\"http://shopping.geocities.jp/hff/img/mail/s.gif\" alt=\"\" width=\"1\" height=\"15\">\n</td>\n</tr>\n";
		}
	}
# 再入荷商品エンド
my $yahoo_renewitem_footer =
<<"HTML_STR_3";
</table>
<!-- 再入荷商品 end-->
HTML_STR_3
Encode::from_to( $yahoo_renewitem_footer, 'utf8', 'shiftjis' );
	$table_renew_item_y .= $yahoo_renewitem_footer;
	# 再入荷エリアをHTMLに追加
	$yahoo_html .= $table_renew_item_y;

# フッター
my $yahoo_footer =
<<"HTML_STR_5";
<!-- フッター start-->
<table width="100%" bgcolor="#000" cellpadding="0" cellspacing="0">
<tr>
<td align="center" height="80" valign="middle">
<font color="#fff" size="1">
Copyright &copy; Newgene Ltd. All Rights Reserved.
</font>
</td>
</tr>
</table>
<!-- フッター end -->
</div>
</body>
</html>
HTML_STR_5
Encode::from_to($yahoo_footer, 'utf8', 'shiftjis');
	# フッターをHTMLに追加
	$yahoo_html .= $yahoo_footer;
	# HTMLファイルに書き込み
	print $output_yhtml_file_disc $yahoo_html;
	close $output_yhtml_file_disc;
	
	
=pod
####################
## 各関数間に跨って使用するグローバル変数
####################
sub create_riframe {
my $html_str1=
<<"HTML_STR_1";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja" lang="ja" dir="ltr">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=Shift_JIS" />
<meta http-equiv="Content-Style-Type" content="text/css" />
<meta http-equiv="Content-Script-Type" content="text/javascript" />
<link rel="stylesheet" href="../../css/style.css" media="all" />
<!--[if lte IE 7]>
<link rel="stylesheet" href="../../css/ie7.css" media="all" />
<![endif]-->
<script type="text/javascript" src="../../js/jquery-1.4.2.js"></script>
<script type="text/javascript" src="../../js/fixHeight.js"></script>
<script type="text/javascript" src="../../js/swapimage.js"></script>
<script type="text/javascript" src="../../js/jquery.js"></script>
<script language="JavaScript" type="text/javascript">jQuery.noConflict();</script>
<script type="text/javascript" src="../../js/lookupzip.js"></script>
<script type="text/javascript" src="../../js/common.js"></script>
HTML_STR_1
        chomp($html_str1);
        # 固定のスタイルシートを追加
        $iframe_html .= $html_str1."\n";
        # 商品名のHTMLを追加
        my $iframe_goods_name = "<title>".$global_entry_goods_name."</title>";
        $iframe_html .= $iframe_goods_name."\n";
my $html_str2=
<<"HTML_STR_2";
</head>
<body id="detail">
<div id="wrapper">
<div id="contents" class="clearfix">
<div class="section clearfix">
<div class="sectionLeft">
<div class="slide">
HTML_STR_2
	chomp($html_str2);
	$iframe_html .= $html_str2."\n";
	# 画像部分のHTMLを追加する
	my $html_str_3 ="";
	# 商品画像URLとして出力する画像を配列に入れる
	my @img_url_list = ();
	@img_url_list = split(/\//,$global_entry_goods_rimagefilename);
	# 商品画像の数を格納する
	my $img_url_list_count = @img_url_list;
	# ブランドのディレクトリを格納する
	my $img_dir = &get_info_from_xml("r_directory");
my $html_str3_1=
<<"HTML_STR_3_1";
<ul class="thumbList fixHeight clearfix">
HTML_STR_3_1
	chomp($html_str3_1);
my $html_str3_2=
<<"HTML_STR_3_2";
<li><a href="javascript:;" rev="http://image.rakuten.co.jp/hff/cabinet/pic/
HTML_STR_3_2
	chomp($html_str3_2);
my $html_str3_3=
<<"HTML_STR_3_3";
 class="swapImage">
HTML_STR_3_3
	chomp($html_str3_3);
my $html_str3_4=
<<"HTML_STR_3_4";
<img src="http://image.rakuten.co.jp/hff/cabinet/pic/
HTML_STR_3_4
	chomp($html_str3_4);
	foreach (my $i=0; $i<=$img_url_list_count-1; $i++){
		if ($i == 0){
			$iframe_html .= "<p class=\"mainImage\"><img src=\"http://image.rakuten.co.jp/hff/cabinet/pic/"."$img_dir"."/1"."/"."$img_url_list[$i]"."\""." alt=\""."$global_entry_goods_name"."\" /></p>"."\n";
			$iframe_html .= $html_str3_1."\n";
		}
		my $img_num = get_r_image_num_from_filename($img_url_list[$i]);
		# サイズバリエーションがあり、かつ、カラーバリエーションがある商品
		my $entry_img_code = &get_7code($img_url_list[$i]);
		# サイズ○カラー○、サイズ×カラー○の商品には正面画像サムネイル下に画像名を入れる
		if ($img_num == 1) {
			my $color_name ="";
			# サイズバリエーションがあり、かつ、カラーバリエーションがあるものはカラーをgoods.csvから抽出する
			if($global_entry_goods_variationflag == 1){
				my $tmp_goods_file_disc;
				if (!open $tmp_goods_file_disc, "<", $input_goods_file_name) {
					&output_log("ERROR!!($!) $input_goods_file_name open failed.");
					exit 1;
				}
				if ($global_entry_goods_size ne ""){
					$color_name = &create_r_lateral_name();
					my $color_str = "カラー";
					Encode::from_to( $color_str, 'utf8', 'shiftjis' );
					if ($color_name eq $color_str){
						# goodsファイルの読み出し(項目行分1行読み飛ばし)
						seek $tmp_goods_file_disc,0,0;
						my $goods_line = $input_goods_csv->getline($tmp_goods_file_disc);
						while($goods_line = $input_goods_csv->getline($tmp_goods_file_disc)){
							if ($entry_img_code == &get_7code(@$goods_line[0])){
								$color_name = @$goods_line[6];
								last;
							}
						}
					}
				}
				# カラーバリエーションのある商品
				else {
					# goodsファイルの読み出し(項目行分1行読み飛ばし)
					seek $tmp_goods_file_disc,0,0;
					my $goods_line = $input_goods_csv->getline($tmp_goods_file_disc);
					my $is_find_goods_info=0;
					while($goods_line = $input_goods_csv->getline($tmp_goods_file_disc)){
						if ($entry_img_code == &get_7code(@$goods_line[0])){
							$color_name = @$goods_line[6];
							last;
						}
					}
				}
				close $tmp_goods_file_disc;
			}
			# 拡大画像URLを追加
			$html_str_3 .="$html_str3_2"."$img_dir"."/"."$img_num"."/"."$img_url_list[$i]"."\""."$html_str3_3";
			# サムネイルコードを追加
			# _sをつけるためにリネームする
			my $img_url_list_file_name = substr("$img_url_list[$i]",0,9);
			my $img_file_name_thum = "$img_url_list_file_name"."s.jpg";
			$html_str_3 .="$html_str3_4"."$img_dir"."/"."$img_num"."/"."$img_file_name_thum"."\""." alt=\""."$global_entry_goods_name"."\" /></a>"."$color_name"."</li>"."\n";
		}
		else {			
			# 拡大画像URLを追加
			my $folder_image_num=$img_num;
			$html_str_3 .=$html_str3_2.$img_dir."/".$folder_image_num."/".get_r_target_image_filename($img_url_list[$i])."\"".$html_str3_3;
			# サムネイルコードを追加
			# _sをつけるためにリネームする
			my $suffix_pos = rindex(get_r_target_image_filename($img_url_list[$i]), '.');
			my $img_url_list_file_name = substr(get_r_target_image_filename($img_url_list[$i]),0,$suffix_pos);
			my $img_file_name_thum = $img_url_list_file_name."s.jpg";
			$html_str_3 .=$html_str3_4.$img_dir."/".$folder_image_num."/".$img_file_name_thum."\" alt=\"".$global_entry_goods_name."\" /></a>"."</li>"."\n";
		}
	}
	$iframe_html .= "$html_str_3"."</ul>"."\n";
my $html_str4=
<<"HTML_STR_4";
</div>
<!--/#sectionLeft--></div>
<!--/#section--></div>
<!--/#contents--></div>
<!--/#wrapper--></div>
</body>
</html>
HTML_STR_4
	chomp($html_str4);
	$iframe_html .="$html_str4";
	print $output_riframe_file_disc $iframe_html;
	close $output_riframe_file_disc;
}
my $global_entry_goods_code=0;
my @done_goods_code =();
########################################################################################################################
##########################　処理開始
########################################################################################################################
&output_log("**********START**********\n");
# goods_img.csv出に項目名を出力
&add_goods_img_csv_name();
# 商品データの作成
my $goods_line = $input_goods_csv->getline($input_goods_file_disc);
while($goods_line = $input_goods_csv->getline($input_goods_file_disc)){
	##### goods.csvファイルの読み出し
	my $entry_goods_code=@$goods_line[0];
	my $entry_goods_code_7 = substr($entry_goods_code,0,7);
	my $entry_goods_price=@$goods_line[16];
	if (length($entry_goods_code) == 5){
		next;
	}
	else {
		$global_entry_goods_code_9 = $entry_goods_code;
		$global_entry_goods_price = $entry_goods_price;
		&add_amazon_price_data();
		my $find_flag = 0;
		# 既に楽天店、ヤフー店で登録している商品管理番号
		foreach my $done_goods_code (@done_goods_code){
			if($done_goods_code == $entry_goods_code_7 ){
				$find_flag = 1;
				last;
			}
		}
		if ($find_flag ==1){
			next;
		}
		else{
			seek $input_dl_item_file_disc,0,0;
			# goodsファイルの読み出し(項目行分1行読み飛ばし)
			my $dlitem_line = $input_dl_item_csv->getline($input_dl_item_file_disc);
			while($dlitem_line = $input_dl_item_csv->getline($input_dl_item_file_disc)){
				# 登録情報から商品コード読み出し
				my $dlitem_code = @$dlitem_line[1];
				my $dlitem_code_7= substr($dlitem_code,0,7);
				my $dlitem_name = @$dlitem_line[3];
				if ($dlitem_code_7 == $entry_goods_code_7) {
					# goods.cvsの商品情報を保持(SKUのものは一つ目に合致した商品の情報を保持)
					$global_entry_goods_code = $dlitem_code;
					$global_entry_goods_r_name = $dlitem_name;
					# 楽天用データを追加
					&add_rakuten_data();
					seek $input_y_data_file_disc,0,0;
					my $ydata_line = $input_y_data_csv->getline($input_y_data_file_disc);
					while($ydata_line = $input_y_data_csv->getline($input_y_data_file_disc)){
						my $ydata_path = @$ydata_line[0];
						my $ydata_name = @$ydata_line[1];
						my $ydata_code = @$ydata_line[2];
						if ($ydata_code == $dlitem_code){
							# Yahoo!用データを追加
							$global_entry_goods_y_path = $ydata_path;	
							$global_entry_goods_y_name = $ydata_name;		
							&add_yahoo_data();
							last;
						}
					}
					push(@done_goods_code,$dlitem_code);
					last;
				}
			}
		}
	}
}
# 処理終了
output_log("Process is Success!!\n");
output_log("**********END**********\n");
# 入力用CSVファイルモジュールの終了処理
$input_goods_csv->eof;
# 出力用CSVファイルモジュールの終了処理
$output_goods_img_csv->eof;
# 入力ファイルのクローズ
close $input_goods_file_disc;
# 出力ファイルのクローズ
close $output_goods_img_disc;
=cut

close(LOG_FILE);

=pod
##############################
## goods_img.csvファイルに項目名を追加
##############################
sub add_goods_img_csv_name {
	my @csv_goods_img_name=("商品コード","S画像ファイル","S画像説明","S画像サムネイル","S画像360","Ｌ画像ファイル","Ｌ画像説明","Ｌ画像サムネイル","Ｌ画像360","Ｃ画像ファイル","Ｃ画像説明","Ｃ画像サムネイル","Ｃ画像360","１画像ファイル","１画像説明","１画像サムネイル","１画像360","２画像ファイル","２画像説明","２画像サムネイル","２画像360","３画像ファイル","３画像説明","３画像サムネイル","３画像360","４画像ファイル","４画像説明","４画像サムネイル","４画像360","５画像ファイル","５画像説明","５画像サムネイル","５画像360","６画像ファイル","６画像説明","６画像サムネイル","６画像360","７画像ファイル","７画像説明","７画像サムネイル","７画像360","８画像ファイル","８画像説明","８画像サムネイル","８画像360","９画像ファイル","９画像説明","９画像サムネイル","９画像360","１０画像ファイル","１０画像説明","１０画像サムネイル","１１画像ファイル","１１画像説明","１１画像サムネイル","１２画像ファイル","１２画像説明","１２画像サムネイル","１３画像ファイル","１３画像説明","１３画像サムネイル","１４画像ファイル","１４画像説明","１４画像サムネイル","１５画像ファイル","１５画像説明","１５画像サムネイル","１６画像ファイル","１６画像説明","１６画像サムネイル","１７画像ファイル","１７画像説明","１７画像サムネイル","１８画像ファイル","１８画像説明","１８画像サムネイル","１９画像ファイル","１９画像説明","１９画像サムネイル","２０画像ファイル","２０画像説明","２０画像サムネイル");
	my $csv_goods_img_name_num=@csv_goods_img_name;
	my $csv_goods_img_name_count=0;
	for my $csv_goods_img_name_str (@csv_goods_img_name) {
		Encode::from_to( $csv_goods_img_name_str, 'utf8', 'shiftjis' );
		$output_goods_img_csv->combine($csv_goods_img_name_str) or die $output_goods_img_csv->error_diag();
		my $post_fix_str="";
		if (++$csv_goods_img_name_count >= $csv_goods_img_name_num) {
			$post_fix_str="\n";
		}
		else {
			$post_fix_str=",";
		}
		print $output_item_file_disc $output_goods_img_csv->string(), $post_fix_str;
	}
	return 0;
}
##############################
## goods_img.csvファイルにデータを追加
##############################
sub add_goods_img_data {
	# 各値をCSVファイルに書き出す
	# コントロールカラム
	$output_item_csv->combine("u") or die $output_item_csv->error_diag();
	print $output_item_file_disc $output_item_csv->string(), ",";
	# 商品管理番号
	$output_item_csv->combine($global_entry_goods_code) or die $output_item_csv->error_diag();
	print $output_item_file_disc $output_item_csv->string(), ",";
	# 商品番号
	print $output_item_file_disc $output_item_csv->string(), ",";
	# 商品名
	$output_item_csv->combine($global_entry_goods_r_name) or die $output_item_csv->error_diag();
	print $output_item_file_disc $output_item_csv->string(), ",";
	# 販売価格
	$output_item_csv->combine($global_entry_goods_price) or die $output_item_csv->error_diag();
	print $output_item_file_disc $output_item_csv->string(), ",";
	# 表示価格
	$output_item_csv->combine("") or die $output_item_csv->error_diag();
	print $output_item_file_disc $output_item_csv->string(), ",";
	# 送料
	my $output_postage_str="";
	if ($global_entry_goods_price >= 5000) {$output_postage_str="1";}
	else {$output_postage_str="0";}
	$output_item_csv->combine($output_postage_str) or die $output_item_csv->error_diag();
	#最後に改行を追加
	print $output_item_file_disc $output_item_csv->string(), "\n";
	return 0;
}
#########################
###  関数　###
#########################
## ログ出力
sub output_log {
	my $day=&to_YYYYMMDD_string();
	print "[$day]:$_[0]";
	print LOG_FILE "[$day]:$_[0]";
}
## 現在日時取得関数
sub to_YYYYMMDD_string {
  my $time = time();
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
  my $result = sprintf("%04d%02d%02d %02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec);
  return $result;
}
=cut