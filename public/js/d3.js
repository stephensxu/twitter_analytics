console.log(gon.report);
var data = gon.report;

var x = d3.scale.linear()
    .domain([0, d3.max(data)])
    .range([0, 420]);

d3.select(".chart")
.selectAll("div")
  .data(data)
.enter().append("div")
  .style("width", function(d) { return d * 20 + "px"; })
  .text(function(d) { return d; });