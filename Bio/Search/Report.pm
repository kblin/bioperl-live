# $Id$
#
# BioPerl module for Bio::Search::Report
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::Search::Report - A sequence database search report

=head1 SYNOPSIS

my $searchio = new Bio::SearchIO(-format => 'blastxml',
				 -file   => 'blsreport.xml');

my $report = $searchio->next_report;

=head1 DESCRIPTION

This object encapsulates the essential for a database search report.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org              - General discussion
  http://bioperl.org/MailList.shtml  - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via
email or the web:

  bioperl-bugs@bioperl.org
  http://bioperl.org/bioperl-bugs/

=head1 AUTHOR - Jason Stajich

Email jason@bioperl.org

Describe contact details here

=head1 CONTRIBUTORS

Additional contributors names and emails here

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::Search::Report;
use vars qw(@ISA);
use strict;

use Bio::Root::Root;
use Bio::Search::ReportI;
use Bio::Search::Subject;

@ISA = qw(Bio::Root::Root Bio::Search::ReportI );

=head2 new

 Title   : new
 Usage   : my $obj = new Bio::Search::Report();
 Function: Builds a new Bio::Search::Report object 
 Returns : Bio::Search::Report
 Args    : -db_name => database name
           -db_size => database size
           -query_name => query sequence name
           -query_size => query sequence size
           -parameters => key value pairs (hash) of parameters
           -statistics => key value pairs (hash) of statistics
           -subjects   => array ref of Bio::Seach::SubjectIs 

=cut

sub new {
  my($class,@args) = @_;

  my $self = $class->SUPER::new(@args);

  $self->{'_subjects'} = [];
  my ($dbname, $dbsize, $qname,$qsize, $pname,$pver,
      $params,$stats,
      $subjects) = $self->_rearrange([qw(DB_NAME
					 DB_SIZE
					 QUERY_NAME
					 QUERY_SIZE
					 PROGRAM_NAME
					 PROGRAM_VERSION
					 PARAMETERS
					 STATISTICS
					 SUBJECTS)],
				     @args);
  $self->{'_subjectindex'} = 0;
  $self->{'_query_name'} = $qname  || '';
  $self->{'_query_size'} = $qsize  || 0;
  $self->{'_db_name'}    = $dbname || '';
  $self->{'_db_size'}    = $dbsize || 0;
  $self->{'_statistics'} = {};
  $self->{'_parameters'} = {};

  defined $pname && ($self->{'_program_name'} = $pname);
  defined $pver  && ($self->{'_program_version'} = $pver);

  if( defined $params ) {
      if( ref($params) !~ /hash/i ) {
	  $self->throw("Must specify a hash reference with the the parameter '-parameters");
      }
      while( my ($key,$value) = each %{$params} ) {
	  $self->add_parameter($key,$value);
      }
  }
  if( defined $stats ) {
      if( ref($stats) !~ /hash/i ) {
	  $self->throw("Must specify a hash reference with the the parameter '-statistics");
      }
      while( my ($key,$value) = each %{$stats} ) {
	  $self->add_statistic($key,$value);
      }
  }

  if( defined $subjects  ) { 
      $self->throw("Must define arrayref of Subjects when initializing a $class\n") unless ref($subjects) =~ /array/i;
  
      foreach my $s ( @$subjects ) {
	  $self->add_subject($s);
      }
  }
  return $self;
}

=head2 next_subject

 Title   : next_subject
 Usage   : my $subject = $report->next_subject;
 Function: Returns the next Subject from a search
 Returns : Bio::Search::SubjectI object
 Args    : none

=cut

sub next_subject{
   my ($self) = @_;   

   my $index = $self->_nextsubjectindex;
   return undef if ( $index > @{$self->{'_subjects'}} );
   return $self->{'_subjects'}->[$index];
}


=head2 database_name

 Title   : database_name
 Usage   : my $name = $report->database_name;
 Function: Returns the name of database searched 
 Returns : string
 Args    : none

=cut

sub database_name{
   my ($self) = @_;
   return $self->{'_db_name'};
}

=head2 database_size

 Title   : database_size
 Usage   : my $size = $report->database_size
 Function: Returns the size of the database searched
 Returns : integer
 Args    : none


=cut

sub database_size{
   my ($self) = @_;
   return $self->{'_db_size'};
}

=head2 query_name

 Title   : query_name
 Usage   : my $q_name = $report->query_name
 Function: Returns the name of the query sequence used to search the database
 Returns : string
 Args    : none

=cut

sub query_name{
   my ($self) = @_;
   return $self->{'_query_name'};
}

=head2 query_size

 Title   : query_size
 Usage   : my $q_size = $report->query_size;
 Function: Returns the size of the query sequence used to search the database
 Returns : integer
 Args    : none

=cut

sub query_size{
   my ($self) = @_;
   return $self->{'_query_size'};
}

=head2 program_name

 Title   : program_name
 Usage   : my $prog_name = $report->program_name
 Function: Returns the full name of the program that generated this report
 Returns : String
 Args    : none


=cut

sub program_name{
   my ($self,@args) = @_;
   return $self->{'_program_name'}; 
}

=head2 program_version

 Title   : program_version
 Usage   : my $version = $report->program_version
 Function: Returns the version number of the program which generated 
           this report
 Returns : String
 Args    : none


=cut

sub program_version{
   my ($self) = @_;
   return $self->{'_program_version'}; 
}

=head2 Bio::Search::Report specific methods

=head2 add_subject

 Title   : add_subject
 Usage   : $report->add_subject($subject)
 Function: Adds a SubjectI to the stored list of subjects
 Returns : Number of SubjectI currently stored
 Args    : Bio::Search::SubjectI

=cut

sub add_subject {
    my ($self,$s) = @_;
    if( $s->isa('Bio::Search::SubjectI') ) { 
	push @{$self->{'_subjects'}}, $s;
    } else { 
	$self->warn("Passed in " .ref($s). " as a Subject which is not a Bio::Search::SubjectI... skipping");
    }
    return scalar @{$self->{'_subjects'}};
}


=head2 rewind

 Title   : rewind
 Usage   : $hsp->rewind;
 Function: Allow one to reset the Subject iteration to the beginning
           Since this is an in-memory implementation
 Returns : none
 Args    : none

=cut

sub rewind{
   my ($self) = @_;
   $self->{'_subjectindex'} = 0;
}


=head2 _nextsubjectindex

 Title   : _nextsubjectindex
 Usage   : private

=cut

sub _nextsubjectindex{
   my ($self,@args) = @_;
   return $self->{'_subjectindex'}++;
}


=head2 get_parameter

 Title   : get_parameter
 Usage   : my $gap_ext = $report->get_parameter('gapext')
 Function: Returns the value for a specific parameter used
           when running this report
 Returns : string
 Args    : name of parameter (string)

=cut

sub get_parameter{
   my ($self,$name) = @_;
   return $self->{'_parameters'}->{$name};
}

=head2 add_parameter

 Title   : add_parameter
 Usage   : $report->add_parameter('gapext', 11);
 Function: Adds a parameter
 Returns : none
 Args    : key  - key value name for this parama
           value - value for this parameter

=cut

sub add_parameter{
   my ($self,$key,$value) = @_;
   $self->{'_parameters'}->{$key} = $value;
}

=head2 available_parameters

 Title   : available_parameters
 Usage   : my @params = $report->available_paramters
 Function: Returns the names of the available parameters
 Returns : Return list of available parameters used for this report
 Args    : none

=cut

sub available_parameters{
   my ($self) = @_;
   return keys %{$self->{'_parameters'}};
}


=head2 get_statistic

 Title   : get_statistic
 Usage   : my $gap_ext = $report->get_statistic('kappa')
 Function: Returns the value for a specific statistic available 
           from this report
 Returns : string
 Args    : name of statistic (string)

=cut

sub get_statistic{
   my ($self,$key) = @_;
   return $self->{'_statistics'}->{$key};
}

=head2 add_statistic

 Title   : add_statistic
 Usage   : $report->add_statistic('lambda', 2.3);
 Function: Adds a parameter
 Returns : none
 Args    : key  - key value name for this parama
           value - value for this parameter

=cut

sub add_statistic {
   my ($self,$key,$value) = @_;
   $self->{'_statistics'}->{$key} = $value;
   return;
}

=head2 available_statistics

 Title   : available_statistics
 Usage   : my @statnames = $report->available_statistics
 Function: Returns the names of the available statistics
 Returns : Return list of available statistics used for this report
 Args    : none

=cut

sub available_statistics{
   my ($self) = @_;
   return keys %{$self->{'_statistics'}};
}

1;
