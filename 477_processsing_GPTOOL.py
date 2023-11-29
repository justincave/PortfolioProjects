import os
import sys
import re
import shutil
import arcpy
import geopandas as gpd


def max_speed_combo(selected_file,tech):
    '''
    Returns census blocks with max speeds without duplicates
        Parameters:
            selected_file (geodataframe): Selected codes from larger merged file
            tech (str): Tech code (ie, DSL, Cable)
        Returns:
            final_gdf (geodataframe): Final blocks with max speeds without duplicates 
    '''
    merge_field = selected_file[['GEOID10', 'ProviderName', 'DBAName','FRN', 'MaxAdDown','MaxAdUp']]
    merge_nodup=merge_field.sort_values(['GEOID10','MaxAdDown','MaxAdUp'],ascending=False).groupby(['GEOID10','DBAName']).first().reset_index()
    final_gdf=selected_file.merge(merge_nodup,on=["GEOID10",'MaxAdDown', 'MaxAdUp', 'FRN'], how='left')
    final_gdf=final_gdf[['GEOID10','ProviderName_y','DBAName_y','FRN','MaxAdDown','MaxAdUp','geometry']]
    final_gdf=final_gdf[final_gdf['ProviderName_y'].notna()]
    final_gdf.drop_duplicates(inplace=True)
    final_gdf['TECH']=tech
    return final_gdf

         
def clean_filenames(out_folder):
    for directname,directnames, files in os.walk(out_folder):
        for f in files:
            filename,ext=os.path.splitext(f)
            new_name=filename.replace(".","")
            newfilename=re.sub('[^a-zA-Z0-9._-]','_',new_name)
            newFilename = newfilename.replace("-", "_")
            newFilenames=newFilename.replace("__","_")
            #print('Renaming to:',newFilenames)
            os.rename(os.path.join(directname,f),os.path.join(directname,newFilenames+ext)) 

def dissolve_merge(out_folder, blank_platform_file, tech):
    arcpy.env.workspace=out_folder
    arcpy.env.overwriteOutput=True
    if tech=="Fiber":
        dissolve_fields=['ProviderNa','DBAName','FRN','MaxAdDown','MaxAdUp','TECH']
    elif tech=="Fixed Wireless":
        dissolve_fields=['ProviderNa','DBAName','FRN','MaxAdDown','MaxAdUp','TECH']
    else:
        dissolve_fields=['ProviderNa','DBAName_y','FRN','MaxAdDown','MaxAdUp','TECH']
        
    for fc in arcpy.ListFeatureClasses(feature_type='Polygon'):
        outfc=arcpy.Describe(fc).baseName+"_DISS"
        #outfc=arcpy.Describe(fc).baseName+"_DISS"
        #arcpy.management.RepairGeometry(fc,True,"ESRI")
        try:
            arcpy.Dissolve_management(fc,outfc,dissolve_fields)
        except:
            arcpy.AddMessage("Could not dissolve {}...".format(fc))
            
    
    fcs=[fc for fc in arcpy.ListFeatureClasses() if os.path.splitext(fc)[0].endswith('_DISS')]
    for shp in fcs:
        outfc_merge=arcpy.Describe(shp).baseName+"_Merge_477"
        #outfc_merge=arcpy.Describe(shp).baseName+"_Merge"
        arcpy.management.Merge([shp,blank_platform_file],outfc_merge)
 
def addfields(out_folder,tech, blank_platform_file):
    fcs=[fc for fc in arcpy.ListFeatureClasses() if os.path.splitext(fc)[0].endswith('_DISS_Merge_477')]
    for shp in fcs:
        try:
            if tech=="Fiber":
                arcpy.CalculateFields_management(shp,"PYTHON3",[["PROVIDER","!ProviderNa!"],["PRVDER_DBA","!DBAName!"],["FCC_FRN","!FRN!"],["MxAdActDwn","!MaxAdDown!"],["MxAdActUp","!MaxAdUp!"]])
                arcpy.DeleteField_management(shp,["ProviderNa","DBAName","FRN","MaxAdDown","MaxAdUp","OBJECTID","Shape_Leng","Shape_Area"])
            
            elif tech=="Fixed Wireless":
                arcpy.CalculateFields_management(shp,"PYTHON3",[["PROVIDER","!ProviderNa!"],["PRVDER_DBA","!DBAName!"],["FCC_FRN","!FRN!"],["MxAdActDwn","!MaxAdDown!"],["MxAdActUp","!MaxAdUp!"]])
                arcpy.DeleteField_management(shp,["ProviderNa","DBAName","FRN","MaxAdDown","MaxAdUp","OBJECTID","Shape_Leng","Shape_Area"])
            else:
                arcpy.CalculateFields_management(shp,"PYTHON3",[["PROVIDER","!ProviderNa!"],["PRVDER_DBA","!DBAName_y!"],["FCC_FRN","!FRN!"],["MxAdActDwn","!MaxAdDown!"],["MxAdActUp","!MaxAdUp!"]])
                arcpy.DeleteField_management(shp,["ProviderNa","DBAName_y","FRN","MaxAdDown","MaxAdUp","OBJECTID","Shape_Leng","Shape_Area"])
        except:
            continue
       
        try:
            arcpy.AddField_management(shp,"FCCForm477","TEXT")
        except:
            continue 
         #arcpy.CalculateFields_management(shp, "PYTHON3",[["FCCForm477","Y"]])
        updateRows=arcpy.UpdateCursor(shp)
        for updateRow in updateRows:
            updateRow.FCCForm477="Y"
            updateRows.updateRow(updateRow)
        del updateRow, updateRows
        
        spatial_ref=arcpy.Describe(blank_platform_file).spatialReference
        arcpy.DefineProjection_management(shp,spatial_ref)
        #arcpy.Project_management(shp,shp,spatial_ref)

def run_tech_fiber_fw(merge_layer_gdf, tech_codes, tech,output_folder, state_abbv,blank_platform_file, date_on_file):
    #Bypasses max speed combo function if Fixed Wireless or Fiber
    merge_sel=merge_layer_gdf[merge_layer_gdf['TechCode'].isin(tech_codes)]
    #print("Selected {} codes....".format(tech))
    arcpy.AddMessage("Selected {} codes....".format(tech))
    #print("NOT Running Max Speed Function on {}...".format(tech))
    arcpy.AddMessage("NOT Running Max Speed Function on {}...".format(tech))
    final_gdf=merge_sel[['GEOID10','ProviderName','DBAName','FRN','MaxAdDown','MaxAdUp','geometry']]
    final_gdf.drop_duplicates(inplace=True)
    final_gdf['TECH']=tech
    group=final_gdf.groupby(['DBAName'])
    
    out_folder=os.path.join(output_folder,"{}_477_Providers_{}".format(state_abbv,tech))
    if os.path.exists(out_folder):
        shutil.rmtree(out_folder, ignore_errors=True)
        os.makedirs(out_folder)
    else:
        os.makedirs(out_folder)
    for dba, frame in group:
        os.chdir(out_folder)
        each_group=group.get_group(dba)
        each_group.to_file("{}_{}_{}_{}.shp".format(state_abbv,dba,tech, date_on_file)) #6 Change to correct processing date
        
    
    clean_filenames(out_folder) 
    dissolve_merge(out_folder,blank_platform_file, tech)
    addfields(out_folder,tech,blank_platform_file)
    
    #print("{} Complete...".format(tech))
    arcpy.AddMessage("{} Complete...".format(tech))
    #print('\n'*2)
    arcpy.AddMessage('\n'*2)
    arcpy.SetProgressorPosition()

        
def run_tech(merge_layer_gdf, tech_codes, tech,output_folder, state_abbv,blank_platform_file,date_on_file):
    if tech=="Fiber":
        arcpy.SetProgressorLabel("Processing 477 Fiber...")
        run_tech_fiber_fw(merge_layer_gdf, tech_codes, tech,output_folder, state_abbv,blank_platform_file, date_on_file)
        
    elif tech=="Fixed Wireless":
       arcpy.SetProgressorLabel("Processing 477 Fixed Wireless...")
      # tech = tech.replace(" ", "_") #won't delete shutil below if don't include this
       run_tech_fiber_fw(merge_layer_gdf, tech_codes,tech,output_folder, state_abbv,blank_platform_file, date_on_file)
       
        
    else:
        arcpy.SetProgressorLabel("Processing 477 {}...".format(tech))
        merge_sel=merge_layer_gdf[merge_layer_gdf['TechCode'].isin(tech_codes)]
        #print("Selected {} codes....".format(tech))
        arcpy.AddMessage("Selected {} codes....".format(tech))
       
        #print("Number of unique selected blocks in {} Selection: {}".format(tech, merge_sel['GEOID10'].nunique()))
        arcpy.AddMessage("Number of unique selected blocks in {} Selection: {}".format(tech, merge_sel['GEOID10'].nunique()))
        #Call Tech functions
        #print("Running Max Speed Function on {}...".format(tech))
        arcpy.AddMessage("Running Max Speed Function on {}...".format(tech))
        #tech="DSL"
        final_gdf=max_speed_combo(merge_sel,tech)
        final_gdf.to_file(os.path.join(output_folder, "{}_477_{}_NoDuplicates_MaxSpeedCombo".format(state_abbv,tech)), driver='ESRI Shapefile')
        
        out_folder=os.path.join(output_folder,"{}_477_Providers_{}".format(state_abbv,tech))
        if os.path.exists(out_folder):
            shutil.rmtree(out_folder, ignore_errors=True)
            os.makedirs(out_folder)
        else:
            os.makedirs(out_folder)
        
        group=final_gdf.groupby(['DBAName_y'])
        for dba, frame in group:
            os.chdir(out_folder)
            each_group=group.get_group(dba)
            each_group.to_file("{}_{}_{}_{}.shp".format(state_abbv,dba,tech, date_on_file)) #6 Change to correct processing date
        
        clean_filenames(out_folder) 
        dissolve_merge(out_folder,blank_platform_file, tech_codes)
        addfields(out_folder, tech_codes,blank_platform_file)
        
        #print("{} Complete...".format(tech))
        arcpy.AddMessage("{} Complete...".format(tech))
        #print('\n'*2)
        arcpy.AddMessage('\n'*2)
        arcpy.SetProgressorPosition()

def get_geodatabase_path(input_table):
  '''Return the Geodatabase path from the input table or feature class.
  :param input_table: path to the input table or feature class 
  '''
  workspace = os.path.dirname(input_table)
  if [any(ext) for ext in ('.gdb', '.mdb', '.sde') if ext in os.path.splitext(workspace)]:
    return workspace
  else:
    return os.path.dirname(workspace)
    

arcpy.SetProgressor("step", "Processing DSL, Cable, Fiber, and FW 477 Data.....", 0, 4, 1)
merge_layer=arcpy.GetParameterAsText(0) #filepath of merge layer
output_folder=arcpy.GetParameterAsText(1) #scratch folder to output folder
state_abbv=arcpy.GetParameterAsText(2)
blank_platform_file=arcpy.GetParameterAsText(3) #blank provider filepath file
date_on_file=arcpy.GetParameterAsText(4) #date to write to file
out_folder_path=arcpy.GetParameterAsText(5) #output folder to save finished files to on server
gdb_path_final=arcpy.GetParameterAsText(6) #Name of .gdb, have to include ".gdb" as string
inbool=arcpy.GetParameterAsText(7)

if not os.path.exists(output_folder):
    os.makedirs(output_folder)

if gdb_path_final:#checks on above inputs, if fails, exit 
    if "gdb" not in gdb_path_final:
        arcpy.AddError("The new name of gdb does not contain '.gdb' extension in text")
        sys.exit(1)

desc=arcpy.Describe(merge_layer)
gdb_path=get_geodatabase_path(merge_layer)

merge_layer_gdf=gpd.read_file(gdb_path,driver="FileGDB", layer=desc.baseName)
#print("Loaded in Merged layer...")
arcpy.AddMessage("Loaded in Merged 477 State layer....")

#split tech codes
dsl_codes=[10,11,12,20,30]
cable_codes=[40,41,42,43]
fiber_codes=[50]
fw_codes=[70]


run_tech(merge_layer_gdf, dsl_codes,"DSL",output_folder, state_abbv,blank_platform_file, date_on_file)
run_tech(merge_layer_gdf, cable_codes,"Cable", output_folder, state_abbv, blank_platform_file, date_on_file)
run_tech(merge_layer_gdf, fiber_codes, "Fiber", output_folder, state_abbv,blank_platform_file,date_on_file)
run_tech(merge_layer_gdf, fw_codes, "Fixed Wireless", output_folder, state_abbv, blank_platform_file, date_on_file)

#Optional parameters below
#This is used to transfer your files form your folder to the server in a GDB
if out_folder_path and gdb_path_final:
    if not arcpy.Exists(os.path.join(out_folder_path,gdb_path_final)):
        arcpy.management.CreateFileGDB(out_folder_path, gdb_path_final)
    
    subfolder_paths = [f.path for f in os.scandir(output_folder) if f.is_dir()]
    final_list=subfolder_paths[2:]
    for subfold in final_list:
        if os.path.isdir(subfold):
            dirname = os.path.basename(subfold)
            split=dirname.split('_')
            result=split.pop()
            newfilename=re.sub('[^a-zA-Z0-9._-]','_',result)
        spatial_ref=arcpy.Describe(blank_platform_file).spatialReference
        feature_dataset=arcpy.management.CreateFeatureDataset(os.path.join(out_folder_path,gdb_path_final), newfilename,spatial_ref)
        arcpy.env.workspace=subfold
        fcs=[fc for fc in arcpy.ListFeatureClasses() if os.path.splitext(fc)[0].endswith('_DISS_Merge_477')]
        for fc in fcs:
            #arcpy.AddMessage("Copying {} from scratch folder to server path .gdb: {}".format(fc,os.path.join(out_folder_path,gdb_path_final)))
            arcpy.FeatureClassToGeodatabase_conversion(fc, feature_dataset)

#optional parameter to save space

if inbool:
    arcpy.AddMessage("Deleting scratch workspace directory.....")
    shutil.rmtree(output_folder,ignore_errors=True)
   # os.rmdir(os.path.join(output_folder,"IL_477_Providers_Fixed Wireless"))
   # os.rmtree(output_folder, ignore_errors=True)
        

arcpy.ResetProgressor()