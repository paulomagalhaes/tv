package com.analytics.tvanalytics;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.MapWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.io.WritableComparable;
import org.apache.hadoop.io.WritableComparator;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Partitioner;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.TextInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.mapreduce.lib.output.TextOutputFormat;
import org.apache.hadoop.mapreduce.lib.partition.HashPartitioner;

public class PromoRetJob {

	static public class PromoPartitioner extends
			Partitioner<Text, MapWritable> {
		public PromoPartitioner() {
			super();
		}

		Partitioner<Text, MapWritable> hashPartitioner = new HashPartitioner<Text, MapWritable>();

		@Override
		public int getPartition(Text key, MapWritable value, int numPartitions) {
			// use date to partition.
			return hashPartitioner.getPartition( 
					new Text(key.toString().split("@")[0]), value,
					numPartitions);
		}
	}

	static public class GroupingComparator extends WritableComparator {

		public GroupingComparator() {
			super(Text.class, true);
		}

		@Override
		public int compare(WritableComparable a, WritableComparable b) {
			String [] aFields = a.toString().split("@");
			String [] bFields = a.toString().split("@");
			
			return aFields[0].compareTo(bFields[0]);
		}

	}

	static public class KeyComparator extends WritableComparator {

		public KeyComparator() {
			super(Text.class, true);
		}

		@Override
		public int compare(WritableComparable a, WritableComparable b) {
			String [] aFields = a.toString().split("@");
			String [] bFields = a.toString().split("@");
			int dateComp = aFields[0].compareTo(bFields[0]);
			if(dateComp != 0){
				return dateComp; 
			}
			return aFields[1].compareTo(bFields[1]);
		}

	}

	/**
	 * @param args
	 * @throws Exception
	 */
	public static void main(String[] args) throws Exception {
		Configuration conf = new Configuration();
		conf.set("mapred.textoutputformat.separator", ",");
		Job job = new Job(conf, "Promocao Retencao Job");
		job.setJarByClass(PromoRetMap.class);
		job.setInputFormatClass(TextInputFormat.class);
		job.setOutputFormatClass(TextOutputFormat.class);

		job.setMapperClass(PromoRetMap.class);
		job.setReducerClass(PromoRetReducer.class);
		
		job.setPartitionerClass(PromoPartitioner.class);
		job.setGroupingComparatorClass(GroupingComparator.class);
		job.setSortComparatorClass(KeyComparator.class);


		job.setMapOutputKeyClass(Text.class);
		job.setMapOutputValueClass(MapWritable.class);

		job.setOutputKeyClass(Text.class);
		job.setOutputValueClass(Text.class);
		job.setNumReduceTasks(args.length > 2 ? Integer.parseInt(args[2]) : 1);

		FileInputFormat.addInputPath(job, new Path(args[0]));
		FileOutputFormat.setOutputPath(job, new Path(args[1]));

		System.exit(job.waitForCompletion(true) ? 0 : 1);

	}

}
