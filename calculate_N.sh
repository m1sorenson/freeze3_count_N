#!/bin/bash
echo -e "study_1\tstudy_2\tancestry\tmale_cases\tmale_controls\tmale_eff_n\tmale_total_n\tfemale_cases\tfemale_controls\tfemale_eff_n\tfemale_total_n\ttotal_eff_n\ttotal_n" > freeze3_counts.tsv
mkdir -p tmp
sed 1d dosage_locations_f3.csv | while read line; do
  study_1=$(echo $line | awk 'BEGIN{FS=","}  {print $1}')
  study_2=$(echo $line | awk 'BEGIN{FS=","}  {print $2}')
  ancgroup=$(echo $line | awk 'BEGIN{FS=","} {print $3}')
  echo $study_1 $study_2

  # merge pheno, cov, fam file to get all individuals for the study
  datadir=/home/pgcdac/DWFV2CJb8Piv_0116_pgc_data/pts/wave3/v1/${study_1}/qc1
  phenofile=pheno/p2_${study_1}_${study_2}_${ancgroup}.pheno
  covfile=pheno/p2_${study_1}_${ancgroup}_${study_2}_pcs.cov
  famfile=$( ls $datadir | grep .gz$ | sed 's/.gz//g' | grep "chr10_000_020").fam
  tmpfile=tmp/${study_1}_${study_2}.sorted
  tail -n+2 $phenofile | awk '{print $1"_"$2}' | LC_ALL=C sort > $tmpfile.pheno
  tail -n+2 $covfile | awk '{print $1"_"$2}' | LC_ALL=C sort > $tmpfile.cov
  awk '{print $1"_"$2,$3,$4,$5,$6}' $datadir/$famfile | LC_ALL=C sort > $tmpfile.fam
  LC_ALL=C join $tmpfile.pheno $tmpfile.fam > $tmpfile.joined
  LC_ALL=C join $tmpfile.cov $tmpfile.joined > $tmpfile.joined2

  # fourth column = sex (1=male, 2=female), fifth column = case/control (1=control, 2=case)
  male_cases=$(awk 'BEGIN{count=0}{if($4 == 1 && $5 == 2){count ++}}END{print count}' $tmpfile.joined2)
  male_controls=$(awk 'BEGIN{count=0}{if($4 == 1 && $5 == 1){count ++}}END{print count}' $tmpfile.joined2)
  male_eff_n=$(awk -v male_cases=$male_cases -v male_controls=$male_controls "BEGIN{ print 4 / (1 / male_cases + 1 / male_controls )}")
  male_total_n=$(( $male_cases + $male_controls ))
  female_cases=$(awk 'BEGIN{count=0}{if($4 == 2 && $5 == 2){count ++}}END{print count}' $tmpfile.joined2)
  female_controls=$(awk 'BEGIN{count=0}{if($4 == 2 && $5 == 1){count ++}}END{print count}' $tmpfile.joined2)
  female_eff_n=$(awk -v female_cases=$female_cases -v female_controls=$female_controls "BEGIN{ print 4 / (1 / female_cases + 1 / female_controls )}")
  female_total_n=$(( $female_cases + $female_controls ))
  total_eff_n=$(awk -v male_cases=$male_cases -v male_controls=$male_controls -v female_cases=$female_cases -v female_controls=$female_controls \
    "BEGIN{ print 4 / (1 / (male_cases + female_cases) + 1 / (male_controls + female_controls) )}")
  total_n=$(( $male_total_n + $female_total_n ))

  # append values to freeze3_counts.tsv
  echo -e "${study_1}\t${study_2}\t${ancgroup}\t${male_cases}\t${male_controls}\t${male_eff_n}\t${male_total_n}\t${female_cases}\t${female_controls}\t${female_eff_n}\t${female_total_n}\t${total_eff_n}\t${total_n}" >> freeze3_counts.tsv
  rm tmp/*
done

rm -r tmp
