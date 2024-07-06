-- Convert all scene material from Phyisical material to GLTF material
-- Created by r.mehedi
-- Created on 3dsMax 2023
-- year 2024
-- extra Material Custom Attribute called "tf" is added
-- free to use tool


fn rgb_to_liner value =
(
  value = (value as float) / 255
  if value <= 0.04045 do
  (
	return (value / 12.92) * 255
  )
  value = ((value + 0.055) / 1.055) ^ 2.4
  return value * 255
)

fn roundUp value =
(
	decimal_Portion = value - value as integer
	if (decimal_Portion >= 0.5) then
	(
		value = ceil value
	)
	else
	(
		value = floor value
	)
)

fn add_materialCustomParametorsAttributes mtl tf:0.0 removeExist:true =
(
	-- remove existing material custom paremeter
	if removeExist and (isProperty Mtl #transmissionFactor) do 
	(
		local attribs = #(
			"customParametors",
			"transmissionFactor"
		)
		for attrib in attribs do 
		(
			removeCustomAttributes_ifHasProp obj attrib
		)
	)
	

	-- making custom material paremeter instance 
	local mtl_cp = attributes customParametors
    (
		parameters main rollout:params 
        (
			transmissionFactor type: #float ui:spn_tf default:0.0
		)
		rollout params "Custom Parametors"
		(
            spinner spn_tf "transmissionFactor" range:[0.0,1.0,0.0] type:#float fieldwidth:30
		)
	)
	
	-- create Custom material parameters
	custAttributes.add mtl mtl_cp #unique baseobject:true
	mtl.customParametors.transmissionFactor = tf
)

fn Physical2GLTF Mtl =
(
	local matName = Mtl.name
	local R_value = Mtl.base_color.R
	local G_value = Mtl.base_color.G
	local B_value = Mtl.base_color.B
			
	
	local Roughness_amt = Mtl.roughness
	
	local opacity4Trc = Mtl.transparency
	local opacity4Tmf
	
	--Calcualting the Standard Material Opacity based on the Physical Material transparencFactor Custom Attribute.
	if (isProperty Mtl #transmissionFactor) do
	(
		opacity4Tmf = Mtl.transmissionFactor
	)
	
	local Emission_Amt = Mtl.emission
	local Emission_color = Mtl.emit_color
	
	local Diffuse_Amt = Mtl.base_weight
	local Bump_Amt = Mtl.bump_map_amt
	
	if (classOf Mtl.base_color_map == RGB_Multiply) do
	(
		R_value = Mtl.base_color_map.color2.R
		G_value = Mtl.base_color_map.color2.G
		B_value = Mtl.base_color_map.color2.B
	)
	local diffuseEnableSt = Mtl.base_color_map_on

	-----------------------------------
	gLTFMtl = glTFMaterial()
	gLTFMtl.showInViewport = true
	-----------------------------------
	
	-- sRGB to LinerRGB color convertion
	
	gLTFMtl.name = matName	
	gLTFMtl.base_color.R = R_value
	gLTFMtl.base_color.G = G_value
	gLTFMtl.base_color.B = B_value
	
	-- gLTFMtl.Specular = Specular_amt  -- canculate the speculatiry later
	
	gLTFMtl.metalness = Mtl.metalness
	gLTFMtl.roughness = Mtl.roughness
	gLTFMtl.emissionColor = (color (Mtl.emit_color.r * Mtl.emission) (Mtl.emit_color.r * Mtl.emission) (Mtl.emit_color.r * Mtl.emission) (Mtl.emit_color.a) )
	
	if opacity4Trc > 0 then
	(
		gLTFMtl.enableTransmission = on
		gLTFMtl.transmission = opacity4Trc
		gLTFMtl.alphaMode = 3
	)
	else
	(
		gLTFMtl.enableTransmission = off
		gLTFMtl.alphaMode	= 1
	)
	
	--DiffuseMap
	if (classOf Mtl.base_color_map == Bitmaptexture) do
	(
		gLTFMtl.baseColorMap = Mtl.base_color_map
	)
	
	if (classOf Mtl.base_color_map == RGB_Multiply) do
	(
		gLTFMtl.baseColorMap =  Mtl.base_color_map.map1
	)
	--gLTFMtl.baseColorMapEnable = Mtl.base_color_map_on -- There is no option to enable or disable base color in GLTF Material in 3DsMax2024
	
	--RoughnessMap
	(
		gLTFMtl.roughnessMap = Mtl.Roughness_Map
		gLTFMtl.roughness = Mtl.roughness
	)
	
	--NormalMap
	if (classOf Mtl.bump_map == Bitmaptexture) do
	(
		gLTFMtl.normalMap = Mtl.bump_map
		-- gLTFMtl.bumpMapEnable = Mtl.bump_map_on -- There is no option to enable or disable NormalMap in GLTF Material in 3DsMax2024
	)
	
	--selfIlluminationMap
	(
		gLTFMtl.emissionMap = Mtl.emission_map
	)
	
	-- Light Map
	gLTFMtl.ambientOcclusionMap = Mtl.diff_rough_map
	-- gLTFMtl.ambientOcclusionMap = Mtl.diff_rough_map_on -- There is no option to enable or disable ambientOcclusionMap in GLTF Material in 3DsMax2024
	
	-- create custom material attribute for transmissionFactor
	if opacity4Tmf != undefined do
	(
		add_materialCustomParametorsAttributes gLTFMtl tf:opacity4Tmf
	)
	
	-- neeed to canculate the speculatiry later -- gLTFMtl.Specular = Specular_amt  -- canculate the speculatiry later

	return gLTFMtl
)


for Mtrl in sceneMaterials do
(
	if (classof Mtrl == PhysicalMaterial) do
	(					
		local ArrMtlAssignedGeo = #()
		for geo in geometry do 
		(
			if(geo.material == Mtrl) do
			(
				append ArrMtlAssignedGeo geo
			)
		)
		ArrMtlAssignedGeo.material = Physical2GLTF Mtrl
	)
)			
redrawViews()
messageBox "Scene physical material has been converted to Gltf material !!!"