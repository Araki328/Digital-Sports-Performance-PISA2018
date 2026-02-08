import pandas as pd
import numpy as np
import os
from sklearn.experimental import enable_iterative_imputer
from sklearn.impute import IterativeImputer

# ================= Configuration =================
# Update these paths to your local directory before running
STU_PATH = r"E:\Y\PISA数据库\STU\cy07_msu_stu_qqq.sas7bdat"
SCH_PATH = r"E:\Y\PISA数据库\SCH\cy07_msu_sch_qqq.sas7bdat"
OUTPUT_DIR = os.path.dirname(STU_PATH)

COUNTRIES_NORDIC = ['FIN', 'SWE', 'DNK', 'NOR']
PROXY_HKG = 'HKG'

# === Variable Lists ===
# Base control variables
BASE_VARS = [
    'IC151Q07HA', 'IC150Q07HA', 'ENTUSE', 'HOMESCH', 'USESCH', 
    'AUTICT', 'INTICT', 'COMPICT', 'ICTHOME', 'ICTSCH', 
    'ESCS', 'GENDER', 'HOMEPOS'
]
# Additional student-level variables
NEW_STU_VARS = [
    'ST100Q01TA', 'BELONG', 'ST016Q01NA', 'STUBMI', 
    'BODYIMA', 'WB150Q01HA', 'SOIAICT', 'EMOSUPP'
]
# School-level variables
NEW_SCH_VARS = [
    'SC001Q01TA', 'STRATIO', 'RATCMP', 'SC155Q08HA', 'SC156Q04HA'
]

# ================= Helper Functions =================
def winsorize_series(s, limits=4):
    """Clip outliers beyond N standard deviations."""
    return s.clip(s.mean() - limits*s.std(), s.mean() + limits*s.std())

def calculate_z_score(x):
    """Standardize variable to Z-score."""
    if x.std() == 0: return x * 0
    return (x - x.mean()) / x.std()

def process_group(df_stu, df_sch, group_name):
    """Process data for a specific group (HK or Nordic)."""
    
    # 1. Merge Student and School Data
    df_stu = df_stu.copy()
    df_sch = df_sch.copy()
    df_stu['CNTSCHID'] = df_stu['CNTSCHID'].astype(str)
    df_sch['CNTSCHID'] = df_sch['CNTSCHID'].astype(str)
    
    df_merged = pd.merge(df_stu, df_sch, on=['CNT', 'CNTSCHID'], how='left', suffixes=('', '_sch'))
    
    # 2. Rename Variables for Clarity
    rename_map = {
        'IC151Q07HA': 'DIGISPORT',
        'IC150Q07HA': 'DIGISPORT_IN',
        'ST004D01T': 'GENDER',
        'ST100Q01TA': 'PE_CLASSES',
        'ST016Q01NA': 'LIFE_SAT',
        'WB150Q01HA': 'HEALTH_SELF',
        'SC155Q08HA': 'T_TRAINING',
        'SC156Q04HA': 'T_DISCUSS',
        'STUBMI': 'BMI'
    }
    # Only rename columns that exist in the dataframe
    current_map = {k: v for k, v in rename_map.items() if k in df_merged.columns}
    df_merged.rename(columns=current_map, inplace=True)
    
    # 3. Select Target Variables
    target_vars_raw = BASE_VARS + NEW_STU_VARS + NEW_SCH_VARS
    final_vars_keep = []
    
    for var in target_vars_raw:
        # check if variable was renamed
        if var in rename_map:
            new_name = rename_map[var]
            if new_name in df_merged.columns:
                final_vars_keep.append(new_name)
        # check if variable exists with original name
        elif var in df_merged.columns:
            final_vars_keep.append(var)
            
    # Include Achievement Scores (PVs) and Weights
    ach_cols = [c for c in df_merged.columns if c.startswith('PV') and ('MATH' in c or 'READ' in c or 'SCIE' in c)]
    meta_cols = ['CNT', 'CNTSCHID', 'W_FSTUWT']
    
    # Create final dataframe
    final_cols = list(set(meta_cols + ach_cols + final_vars_keep))
    df_final = df_merged[final_cols].copy()
    
    # 4. Imputation and Standardization
    numeric_cols = df_final.select_dtypes(include=[np.number]).columns.tolist()
    cols_to_process = [c for c in numeric_cols if c not in ach_cols + ['W_FSTUWT']]
    
    # Drop columns that are completely empty to avoid errors
    valid_cols = []
    for col in cols_to_process:
        if df_final[col].notnull().sum() > 0:
            valid_cols.append(col)
    cols_to_process = valid_cols

    if cols_to_process:
        # Iterative Imputer (MICE)
        imputer = IterativeImputer(max_iter=5, random_state=42)
        try:
            df_final[cols_to_process] = imputer.fit_transform(df_final[cols_to_process])
            
            # Standardization (Z-score)
            for col in cols_to_process:
                # Winsorize extreme outliers before standardization
                df_final[col] = winsorize_series(df_final[col])
                df_final[f"z_{col}"] = calculate_z_score(df_final[col])
        except Exception:
            # Fallback if imputation fails
            pass
            
    return df_final

def main():
    # Load Student Data
    df_stu = pd.read_sas(STU_PATH, format='sas7bdat', encoding='utf-8')
    if df_stu['CNT'].dtype == object:
        df_stu['CNT'] = df_stu['CNT'].apply(lambda x: x.decode('utf-8') if isinstance(x, bytes) else str(x)).str.strip()
    
    # Load School Data
    df_sch = pd.read_sas(SCH_PATH, format='sas7bdat', encoding='utf-8')
    if df_sch['CNT'].dtype == object:
        df_sch['CNT'] = df_sch['CNT'].apply(lambda x: x.decode('utf-8') if isinstance(x, bytes) else str(x)).str.strip()

    # Process Group: China Hong Kong (HKG)
    df_hkg_raw = df_stu[df_stu['CNT'] == PROXY_HKG]
    df_sch_hkg = df_sch[df_sch['CNT'] == PROXY_HKG]
    
    if not df_hkg_raw.empty:
        df_hkg = process_group(df_hkg_raw, df_sch_hkg, "HKG")
        output_path_hkg = os.path.join(OUTPUT_DIR, "PISA2018_HKG_FULL_v4.csv")
        df_hkg.to_csv(output_path_hkg, index=False, encoding='utf-8-sig')
    
    # Process Group: Nordic Countries
    df_nor_raw = df_stu[df_stu['CNT'].isin(COUNTRIES_NORDIC)]
    df_sch_nor = df_sch[df_sch['CNT'].isin(COUNTRIES_NORDIC)]
    
    if not df_nor_raw.empty:
        df_nor = process_group(df_nor_raw, df_sch_nor, "Nordic")
        output_path_nor = os.path.join(OUTPUT_DIR, "PISA2018_Nordic_FULL_v4.csv")
        df_nor.to_csv(output_path_nor, index=False, encoding='utf-8-sig')

if __name__ == "__main__":
    main()