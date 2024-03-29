# CONNECTING TO TILESERVER-GL WMTS FROM QGIS
### 1. Go to the [RBT](https://rbt-sf-ms-bdms-mvp-dev.apps.kubic.xc.nga.mil/) Tileserver-GL endpoint and copy the WMTS URL by right clicking on the "WMTS" button for the Style you want to view, and clicking "copy link address".
   ![WMTS URL](../images/wmts_url.png)
### 2. Right click the "WMS/WMTS" button in your QGIS Browser TOC, and click "New Connection".
   ![WMTS CONNECTION](../images/wmts_connection.png)
### 3. Under Connection Details type in a Name and copy the WMTS URL from step 1 into the URL. Choose "High (192 DPI)" from "WMTS server-side tile pixel ratio" and then click "OK".
   ![CONNECTION DETAILS](../images/connection_details.png)
### 4. Click the drop down arrow on your WMTS connection "RBT-TLM-3395", then right click the raster layer click "Add Layer to Project".
   ![CONNECTION DETAILS](../images/add_layer.png)
### 5. Within the Layers TOC right click the "RBT-TLM-3395" layer and click on "Properties".
   ![CONNECTION DETAILS](../images/properties.png)
### 6. Then within the "Layer Properties" pop-up select "Symbology" and change Resampling to "Bilinear" for both Zoomed in and out, then click "OK".
   ![CONNECTION DETAILS](../images/layer_properties.png)
### 7. You now have a WMTS Basemap!
   ![CONNECTION DETAILS](../images/basemap.png)
# CONNECTING TO TILESERVER-GL WMTS FROM ARCGIS PRO
### 1. Go to the [RBT](https://rbt-sf-ms-bdms-mvp-dev.apps.kubic.xc.nga.mil/) Tileserver-GL endpoint and copy the WMTS URL by right clicking on the "WMTS" button for the Style you want to view, and clicking "copy link address".
   ![WMTS URL](../images/wmts_url.png)
### 2. click the "Connections" drop down button in your ArcGIS PRO tool bar, select "Server", then click on "New WMTS Server".
   ![WMTS SERVER](../images/new_wmts_server.png)
### 3. In the "Add WMTS Server Connection" pop-up under "Server URL" paste the URL from Step 1 and click "OK".
   ![WMTS SERVER CONNECTION](../images/wmts_server_connection.png)
### 4. In the "Catalog" select "Servers" and right click the "RBT-TLM-3395" raster and select "Add To New Map".
   ![ADD TO MAP](../images/add_to_map.png)
### 5. You now have a WMTS Basemap!
   ![CONNECTION DETAILS](../images/arcgis_basemap.png)