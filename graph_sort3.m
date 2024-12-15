function [x,y,z] = graph_sort3(x,y,z)

G = graph(squareform( pdist([x,y,z], 'Chebychev' ) ) == 1); 
H = rmedge(G,find(all(ismember(G.Edges.EndNodes,find(degree(G) > 2)),2))); %if a pixel is connected to more than 2 pixels, remove the unnecessary edge

k = find(degree(H) == 1, 1); %define the starting point as the first node with only one adjacent pixel. THIS IS FRAGILE FOR CIRCLES
if isempty(k)
    k = 1;
end
v = dfsearch(H,k); %discover all points in the graph, starting at our starting point. return the index of discovery (such that you traverse the shortest path)
x = x(v); %reorder the coordinates in order of discovery
y = y(v);
z = z(v);
