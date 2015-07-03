require 'open3'

module Ubiquity

  module StorNext

    # NAME
    # snfsdefrag − StorNext File System Defrag Utility
    #
    # SYNOPSIS
    # snfsdefrag [-DdPqsv] [-G group] [-K key] [-k key] [-m count] [-r] [-S file] Target [Target...]
    # snfsdefrag -e [-b] [-G group] [-K key] [-r] [-t] [-S file] Target [Target...]
    # snfsdefrag -E [-b] [-G group] [-K key] [-r] [-t] [-S file] Target [Target...]
    # snfsdefrag -c [-G group] [-K key] [-r] [-t] [-T] [-S file] Target [Target...]
    # snfsdefrag -p [-DvPq] [-G group] [-K key] [-m count] [-r] [-S file] Target [Target...]
    # snfsdefrag -l [-Dv] [-G group] [-K key] [-m count] [-r] [-S file] Target [Target...]
    #
    # DESCRIPTION
    # snfsdefrag is a utility for defragmenting files on a StorNext file system by relocating the data in a file to a
    # smaller set of extents. Reducing the number of extents in a file improves performance by minimizing disk
    # head movement when performing I/O. In addition, with fewer extents, StorNext File System Manager
    # (FSM) overhead is reduced.
    # snfsdefrag can be used to migrate files off of an existing stripe group and on to other stripe groups by using
    # the -G option and setting the -m option to 0. If affinities are associated with a file that is being defragmented,
    # new extents are created using the existing file affinity, unless being overridden by the -k option. If the
    # -k option is specified, the files are moved to a stripe group with the specified affinity. Without -k, files are
    # moved to any available stripe group. This migration capability can be especially useful when a stripe group
    # is going out of service. See the use of the -G option in the EXAMPLES section below.
    # In addition to defragmenting and migrating files, snfsdefrag can be used to list the extents in a file (see the
    # -e option) or to prune away unused space that has been preallocated for the file (see the -p option).
    #
    # OPTIONS
    # -b Show extent size in blocks instead of kilobytes. Only useful with the -e and -E (list extents) options.
    # -c This option causes snfsdefrag to just display an extent count instead of defragmenting files.
    #    See also the -t and -T options.
    # -D Turns on debug messages.
    # -d Causes snfsdefrag to operate on files containing extents that have depths that are different than the
    #    current depth for the extent’s stripe group. This option is useful for reclaiming disk space that has
    #    become "shadowed" after cvupdatefs has been run for stripe group expansion. Note that when -d
    #    is used, a file may be defragmented due to the stripe depth in one or more of its extents OR due to
    #    the file’s extent count.
    # -e This option causes snfsdefrag to not actually attempt the defragmentation, but instead report the
    #    list of extents contained in the file. The extent information includes the starting file relative offset,
    #    starting and ending stripe group block addresses, the size of the extent, the depth of the extent, and
    #    the stripe group number. See also the -t option.
    # -E This option has the same effect as the −e option except that file relative offsets and starting and
    #    ending stripe group block addresses that are stripe-aligned are highlighted with an asterisk (*).
    #    Also, starting stripe group addresses that are equally misaligned with the file relative offset are
    #    highlighted with a plus sign (+). See also the -t option.
    # -G stripegroup
    #    This option causes snfsdefrag to only operate on files having at least one extent in stripegroup,
    #    which is the stripe group index obtained by running the show subcommand from the cvadmin
    #    utility. Note that multiple -G options can be specified to match files with an extent in at least one
    #    of the specified stripe groups.
    # -K key This option causes snfsdefrag to only operate on source files that have the supplied affinity key. If
    #    key is preceded by ’!’ then snfsdefrag will only operate on source files that do not have the affinity key.
    #    See EXAMPLES below.
    # -k key Forces the new extent for the file to be created on the stripe group specified by key.
    # -l This option causes snfsdefrag to just list candidate files.
    # -m count
    #    This option tells snfsdefrag to only operate on files containing more than count extents. By default,
    #    the value of count is 1. A value of zero can be specified to operate on all files with at least
    #    one extent. This is useful for moving files offastripe group.
    # -p Causes snfsdefrag to perform a prune operation instead of defragmenting the file. During a prune
    #    operation, blocks beyond EOF that have been preallocated either explicitly or as part of inode expansion
    #    are freed, thereby reducing disk usage. Files are otherwise unmodified. Note: While
    #    prune operations reclaim unused disk space, performing them regularly can lead to free space fragmentation.
    # -P Lists skipped files.
    # -q Causes snfsdefrag to be quiet.
    # -r [TargetDirectory]
    #    This option instructs snfsdefrag to recurse through the TargetDirectory and attempt to defragment
    #    each fragmented file that it finds. If TargetDirectory is not specified, the current directory is assumed.
    # -s Causes snfsdefrag to perform allocations that are block-aligned. This can help performance in situations
    #    where the I/O size perfectly spans the width of the stripe group’s disks.
    # -S file Writes status monitoring information in the supplied file. This is used internally by StorNext and
    #    the format of this file may change.
    # -t This option adds totals to the output of the −c, −e, or −E options. Output at the end indicates how
    #    many regular files were visited, how many total extents were found from all files, and the average
    #    # of extents per file. Also shown are the number of files with one extent, the number of files with
    #    more than one extent, and the largest number of extents in a single file.
    # -T This option acts like -t, except that with -c, only the summary output is presented. No information
    #    is provided for individual files.
    # -v Causes snfsdefrag to be verbose.
    #
    # EXAMPLES
    # Count the extents in the file foo.
    #   rock% snfsdefrag -c foo
    #
    # Starting in directory, dir1, recursively count all the files and their extents and then print the grand total and
    # average number of extents per file.
    #   rock% snfsdefrag -r -c -t dir1
    #
    # List the extents in the file foo.
    #   rock% snfsdefrag -e foo
    #
    # Defragment the file foo.
    #   rock% snfsdefrag foo
    #
    # Defragment the file foo if it contains more than 2 extents. Otherwise, do nothing.
    #   rock% snfsdefrag -m 2 foo
    #
    # Traverse the directory abc and its sub-directories and defragment every file found containing more than one extent.
    #   rock% snfsdefrag -r abc
    #
    # Traverse the directory abc and its sub-directories and defragment every file found having one or more extents
    # whose depth differs from the current depth of extent’s stripe group OR having more than one extent.
    #   rock% snfsdefrag -rd abc
    #
    # Traverse the directory abc and its sub-directories and only defragment files having one or more extents
    # whose depth differs from the current depth of extent’s stripe group. This situation would arise after cvupdatefs
    # has been used to expand the depth of a stripe group. The high value for -m ensures that only extents
    # with different depth values are defragmented.
    #   rock% snfsdefrag -m 9999999999 -rd abc
    #
    # Traverse the directory abc and recover unused preallocated disk space in every file visited.
    #   rock% snfsdefrag -rp abc
    #
    # Force the file foo to be relocated to the stripe group with the affinity key "fast"
    #   rock% snfsdefrag -k fast -m 0 foo
    #
    # If the file foo has the affinity fast, then move its data to a stripe group with the affinity slow.
    #   rock% snfsdefrag -K fast -k slow -m 0 foo
    #
    # If the file foo does NOT hav e the affinity slow, then move its data to a stripe group with the affinity slow.
    #   rock% snfsdefrag -K ’!slow’ -k slow -m 0 foo
    #
    # Traverse the directory abc and migrate any files containing at least one extent in stripe group 2 to any nonexclusive
    # stripe group.
    #   rock% snfsdefrag -r -G 2 -m 0 abc
    #
    # Traverse the directory abc and migrate any files containing at least one extent in stripe group 2 to stripe
    # groups with the affinity slow. It is advised that the source stripe group be marked as read-only before running
    # the following command, if you wish to retire the source stripe group.
    #   rock% snfsdefrag -r -G 2 -k slow -m 0 abc
    #
    # Traverse the directory abc list any files that have the affinity fast and having at least one extent in stripe
    # group 2. It is advised that the source stripe group be marked as read-only before running the following
    # command, if you wish to retire the source stripe group.
    #   rock% snfsdefrag -r -G 2 -k fast -l -m 0 abc
    #
    # NOTES
    # If snfsdefrag is run on a Windows client, the user must have read and write access to the file. If snfsdefrag
    # is run on a Unix client, only the owner of a file or superuser is allowed to defragment a file. (To act as superuser
    # on a StorNext file system, in addition to becoming the user root, the configuration option GlobalSuperUser
    # must be enabled. See snfs_config(5) for more information.)
    # snfsdefrag will not operate on open files, files that have been modified in the past 10 seconds and files with
    # modification times in the future. If a file is modified while defragmentation is in progress, snfsdefrag will
    # abort and the file will be skipped.
    # snfsdefrag skips special files and files containing holes.
    # snfsdefrag does not follow symbolic links.
    # When operating on a file marked for PerfectFit allocations, snfsdefrag will "do the right thing" and preserve
    # the PerfectFit attribute.
    # While performing defragmentation, snfsdefrag creates a temporary file named TargetFile__defragtmp. If
    # the command is interrupted, snfsdefrag will attempt to remove this file. However, if snfsdefrag is killed or
    # a power failure occurs, the temporary file may be left behind. If snfsdefrag is subsequently re-run and attempts
    # defragmentation, it will clean up any stale temporary files encountered. But if snfsdefrag is not run
    # again, it will be necessary to find and remove the temporary file as it will continue to consume space. Note
    # that user files having the __defragtmp extension should not be created if snfsdefrag is to be run.
    # snfsdefrag will fail if it cannot locate a set of extents that would reduce the current extent count on a file.
    # When files being defragmented reside in a managed file system with stub files enabled and
    # CLASS_STUB_READ_AHEAD is set in the fs_sysparams file, the operation could cause file retrieval.
    #
    # ADVANCED FRAGMENTATION ANALYSIS
    # There are two major types of fragmentation to note: file fragmentation and free space fragmentation. File
    # fragmentation is measured by the number of file extents used to store a file. A file extent is a contiguous allocation
    # unit within a file. When a large enough contiguous space cannot be found to allocate to a file, multiple
    # smaller file extents are created. Each extent represents a different physical spot in a stripe group. Requiring
    # multiple extents to address file data impacts performance in a number of ways. First, the file system
    # must do more work looking up locations for a file’s data. Also, having file data spread across many different
    # locations in the file system requires the storage hardware to do more work while reading a file. On a
    # disk there will be increased head movements, as the drive seeks around to read in each data extent. Many
    # disks also attempt to optimize I/O performance, for example, by attempting to predict upcoming read locations.
    # When a file’s data is contiguous these optimizations work well. However, with a fragmented file the
    # drive optimizations are not nearly as efficient.
    # A file’s fragmentation should be viewed more as a percentage than as a hard number. While it’s true that a
    # file of nearly any size with 50000 fragments is extremely fragmented and should be defragmented, a file
    # that has 500 fragments that are mostly one or two file system blocks (4096 bytes) in length is also very
    # fragmented. Keeping files to under 10% fragmentation is the ideal, and how close you come to that ideal is
    # a compromise based on real-world factors (file system use, file sizes and their life span, opportunities to run
    # snfsdefrag, etc.).
    # In an attempt to reduce fragmentation (file and free space), Adminstrators can try using the Allocation Session
    # Reservation feature. This feature is managed using the GUI or by modifying the AllocSessionReservationSize
    # parameter, see snfs_config(5). See also the StorNext Tuning Guide.
    # Some common causes of fragmentation are having very full stripe groups (possibly because of affinities), a
    # file system that has a lot of fragmented free space (deleting a fragmented file produces fragmented free
    # space), heavy use of CIFS or NFS which typically use out-of-order allocations resulting in unoptimized
    # (uncoalesced) allocations, or an application that writes files in a random order.
    # snfsdefrag is designed to detect files which contain file fragmentation and coalesce that data onto a minimal
    # number of file extents. The efficiency of snfsdefrag is dependent on the state of the file system’s free
    # data blocks, or free space.
    # The second type of fragmentation is free space fragmentation. The file system’s free space is the pool of unallocated
    # data blocks. Space allocation for new files, as well as allocations for extending existing files,
    # comes from the file system’s free space. Free space fragmentation is measured by the number of fragments
    # of contiguous free blocks. Fragmentation in the file system’s free space affects the file system’s ability to
    # allocate large extents. A file can only have an extent as large as the largest contiguous block of free space.
    # Thus free space fragmentation can lead to file fragmentation in larger files. As snfsdefrag processes fragmented
    # files it attempts to use large enough free space fragments to create a new defragmented file space. If
    # free space is too fragmented snfsdefrag may not be able to allocate a large enough extent for the file’s data.
    # In the case that snfsdefrag must use multiple extents in the defragmented file, it will only proceed if the
    # processed file will have fewer extents than the original. Otherwise snfsdefrag will abort that file’s defrag
    # process and move on to remaining defrag requests.
    #
    # FRAGMENTATION ANALYSIS EXAMPLES
    # The following examples include reporting from snfsdefrag as well as cvfsck. Some examples require additional
    # tools such as awk and sort.
    # Reporting a specific file’s fragmentation (extent count).
    #   # snfsdefrag -c <filename>
    #
    # Report all files, their extents, the total # of files and extents, and the average number of extents per files. Beware
    # that this command walks the entire file system so it can takeawhile and cause the performance of applications
    # to degrade while running.
    #   # snfsdefrag -r -c -t <mount point>
    #
    # The following command will create a report showing each file’s path, followed by extent count, with the report
    # sorted by extent count. Files with the greatest number of extents will show up at the top of the list.
    # Replace <fsname> in the following example with the name of your StorNext file system. The report is written
    # to stdout and should be redirected to a file.
    #   # cvfsck -x <fsname> | awk -F, ’{if (NF == 14) \
    #     print($6", "$7)}’ | sort -uk1 -t, | sort -nrk2 -t,
    #
    # This next command will display all files with at least 10 extents and with a size of at least 1MB. Replace
    # <fsname> in the following example with the name of your StorNext file system. The report is written to
    # stdout and can be redirected to a file.
    #   # echo "#extents file size av. extent size filename"; \
    #     cvfsck -r <fsname> | awk ’{if (NF == 8 && $03 > 1048576 && \
    #     $05 > 10) printf("%8d %10d %16d %10s\n", $5, $3, $03/$05, $8)}’ \
    #     | sort -nr
    #
    # The next command displays a report of free space fragmentation. This allows an administrator to see if free
    # space fragmentation may affect future allocation fragmentation. See cvfsck(8) man page for description of
    # report output.
    #   # cvfsck -a -t -f <fsname>
    #
    # The fragmentation detected RAS warning message may sometimes refer to an inode number instead of a
    # file name. To find the file name associated with the inode number on non-Windows clients, fill the file system
    # mount point and the decimal inum from the RAS message into the following find command. The file
    # name can then be used to defragment the file. There may be more than one file that matches the 32-bit inode
    # number.
    #   # find <mount_point> -inum <decimal_inum>
    #   # snfsdefrag <filename>
    #
    # For Windows clients:
    # Using a DOS shell, CD to the directory containing the StorNext binaries and run the cvstat command as
    # follows: The <fname> parameter is the drive letter:/mount point and the <inum> parameter has either the
    # decimal or hexidecimal 64-bit inode number from the RAS message. For example:
    #   c:\> cd c:\Program Files\StorNext\bin
    #   c:\> cvstat fname=j:\ inum=0x1c0000004183da
    #
    # FILES
    # /usr/cvfs/config/*.cfgx
    #
    # SEE ALSO
    # cvfsck(8), cvcp(1), cvmkfile(1), snfs_config(5), cvaffinity(1)
    class SNFSDefrag

      DEFAULT_EXECUTABLE_FILE_PATH = '/usr/cvfs/bin/snfsdefrag'
      DEFAULT_PARSE_VERBOSE_DATA = true
      DEFAULT_RETURN_RAW_RESPONSE = false

      attr_accessor :logger,
                    :executable_file_path,
                    :return_raw_response,
                    :parse_verbose_data

      def initialize(args = { })
        @logger = args[:logger] ? args[:logger].dup : Logger.new(args[:log_to] || STDOUT)
        logger.level = args[:log_level] if args[:log_level]

        @executable_file_path = args[:executable_file_path] || DEFAULT_EXECUTABLE_FILE_PATH
        @return_raw_response = args.fetch(:return_raw_response, DEFAULT_RETURN_RAW_RESPONSE)
        @parse_verbose_data = args.fetch(:parse_verbose_data, DEFAULT_PARSE_VERBOSE_DATA)
      end

      def extent_counts(path, options = { })
        command_line = [ '-c' ]
        command_line << '-b' if options[:blocks]

        stripe_group = options[:stripe_group]
        command_line << '-G' << stripe_group if stripe_group

        affinity_key = options[:affinity_key]
        command_line << '-K' << affinity_key if affinity_key

        command_line << '-r' if options[:recursive]

        command_line << '-t' if options[:totals]

        command_line << path
        raw_response = execute(command_line)
        return raw_response if options.fetch(:return_raw_response, return_raw_response)
      end

      def list_extents_parse_extents(file_data)
        file_data = file_data.lines.to_a
        file_data.shift while file_data.first.strip.empty?
        file_data.pop while file_data.last.strip.empty?

        file_path, headers = file_data.shift(2)
        file_path.strip!.chop!
        headers.strip!.squeeze!(' ')
        extents = file_data.lines.map { |l| Hash[headers.zip(l.strip.squeeze(' ').split(' '))] }
        { :path => file_path, :extents => extents }
      end

      # snfsdefrag -e [-b] [-G group] [-K key] [-r] [-t] [-S file] Target [Target...]
      # /Volumes/MEDIA/LA01_SAN/72LA_ARCHIVE/EDITORIAL/2K_SPORTS//NBA/K12/E_TK_NB_KTW_20150305/UNCOMPRESSED/BROADCAST/HD/._2KSP1563H_NBA2K11_Kids_30_Uncompressed.mov:
      # #      group  frbase           fsbase         fsend          kbytes       depth
      # 0      5      0x0              0x3718cd32e    0x3718cd334    28           2
      # 1      5      0x7000           0x3718cd901    0x3718cd906    24           2
      def list_extents(path, options = { })
        command_line = [ '-e' ]
        command_line << '-b' if options[:blocks]

        stripe_group = options[:stripe_group]
        command_line << '-G' << stripe_group if stripe_group

        affinity_key = options[:affinity_key]
        command_line << '-K' << affinity_key if affinity_key

        command_line << '-r' if options[:recursive]

        command_line << '-t' if options[:totals]

        command_line << path
        raw_response = execute(command_line)
        return raw_response if options.fetch(:return_raw_response, return_raw_response)

        file_extents = { }
        file_path = nil
        headers = nil
        extents_data = [ ]
        raw_response.each_line do |line|
          l = line.strip
          if l.empty?
            unless extents_data.empty?
              file_extents[file_path] = extents_data.map { |e| Hash[ headers.zip(e) ] }
            end
            file_path = nil
            headers = nil
            extents_data = [ ]
            next
          elsif file_path.nil?
            file_path = l.strip.chop
          elsif headers.nil?
            headers = l.strip.squeeze(' ').split(' ')
          else
            extents_data << l.strip.squeeze(' ').split(' ')
          end
        end
        file_extents[file_path] = extents_data.map { |e| Hash[ headers.zip(e) ] } unless file_path.nil? or extents_data.empty?

        file_extents
      end

      # snfsdefrag -l [-Dv] [-G group] [-K key] [-m count] [-r] [-S file] Target [Target...]
      def list_candidates(path, options = { })
        return path.map { |p| list_candidates(p, options) } if path.is_a?(Array)

        command_line = [ '-l' ]
        command_line << '-r' if options[:recursive]
        command_line << '-v' if (verbose = options[:verbose])
        command_line << '-D' if options[:debug]

        stripe_group = options[:stripe_group]
        command_line << '-G' << stripe_group if stripe_group

        affinity_key = options[:affinity_key]
        command_line << '-K' << affinity_key if affinity_key

        minimum_extents = options[:minimum_extents]
        command_line << '-m' << minimum_extents if minimum_extents

        command_line << path
        raw_response = execute(command_line)
        return raw_response if options.fetch(:return_raw_response, return_raw_response)

        raise raw_response if raw_response.start_with?('Error: ')

        candidates = [ ]
        raw_response.each_line { |c| _c = c.strip; next if c.empty? or c.nil?; candidates << _c }

        candidates.compact!

        return candidates unless verbose and options.fetch(:parse_verbose_data, parse_verbose_data)

        candidates.map do |c|
          match = /(.*):\s?(\d+)\sextent[s]?:\s?(.*)/.match(c)
          next unless match
          { :path => $1, :extent_count => $2, :message => $3}
        end.compact
      end

      def execute(command_line = '', options = { })
        if command_line.is_a?(Array)
          command_line = [ executable_file_path ] + command_line
          command_line = command_line.shelljoin unless !options.fetch(:shelljoin, true)
        else
          command_line = %("#{executable_file_path}" ) << command_line
        end
        command_line.strip!

        logger.debug { %(Executing: '#{command_line}') }
        response = `#{command_line}`
        logger.debug { "Response: #{response}" }
        response
      end

      # SNFSDefrag
    end

    # StorNext
  end

  # Ubiquity
end
