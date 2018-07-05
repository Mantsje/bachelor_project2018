module syntax_highlighting::regexes::CharRanges

import Grammar;
import IO;

list[CharRange] clampToAscii(list[CharRange] ranges) {
	new_ranges = [];
	for (r <- ranges) {
		if (r.begin > 127) continue;
		if(r.end > 127) new_ranges += \range(r.begin, 127);
		else new_ranges += r;
	}
	println("<ranges> -\> <new_ranges>");
	return new_ranges;
}

str int2hex(int n) {
	hex = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"];
	out = "";
	while (n >= 16) {
		int modulo = (n%16);
		n = (n - modulo) / 16;
		out = "<hex[modulo]><out>";
	}
	out = "<hex[n]><out>";
	return out;
}

str charRangesToString(charrange:Symbol::\char-class(list[CharRange] ranges), bool asciiOnly=false) {
	if(asciiOnly) {
		ranges = clampToAscii(ranges);
		charrange = \char-class(ranges);
	}
	inner = "";
	for( r <- ranges) {
		if (r.end - r.begin > 0) {
			inner += "\\x{<int2hex(r.begin)>}-\\x{<int2hex(r.end)>}";
		} else {
			inner += "\\x{<int2hex(r.begin)>}";
		}
	}
	return "[<inner>]";
}