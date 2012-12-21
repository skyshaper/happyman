package App::Happyman::Plugin::RandomTopic;
use v5.16;
use Moose;

with 'App::Happyman::Plugin';

use AnyEvent;

has _lines => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    builder => '_build_lines',
);

has _timer => (
    is => 'ro',
    builder => '_build_timer',
    lazy => 1,
);

has _topic_time => (
    is => 'rw',
    isa => 'Int',
);

has check_interval => (
    is => 'ro',
    isa => 'Int',
    default => 1800,
);

has min_topic_age => (
    is => 'ro',
    isa => 'Int',
    default => 172800,
);

sub BUILD {
    my ($self) = @_;
    $self->_timer();
}


sub _build_lines {
    my ($self) = @_;
    my @lines;

    while (<DATA>) {
      chomp;
      push @lines, $_;
    }

    return \@lines;
}

sub _random_line {
    my ($self) = @_;
    return @{$self->_lines}[rand @{$self->_lines}];
}

sub on_topic {
    my ($self, $topic) = @_;
    $self->_topic_time(time);
}


sub _build_timer {
    my ($self) = @_;

    return AE::timer(0, $self->check_interval, sub {
        say 'Checking topic';

        return if not defined $self->_topic_time();
        return if (time - $self->_topic_time()) < $self->min_topic_age;

        my $line = $self->_random_line();
        say $line;
        $self->conn->set_topic($line);
    });
}

__PACKAGE__->meta->make_immutable();


__DATA__
I ride the morning train
People come and go
So many different faces
As the city passes by
I watch their tired eyes
Journeys never made
Broken dreams of leaving
Fill the streets with dust
This is our final journey
It's the end of the line
Constantly in transit
We just want to go home
The rain that falls for weeks
Painting pictures on the streets
Twisted stars beneath my feet
I cruise the crowd
I could be one of them
Going back and forth
Between familiar places
As my blood turns cold
I watch with gypsy eyes
Secrets never told
Stolen years of yearning
Turn their tears to dust
This is our final journey
It's the end of the line
Constantly in transit
We just want to go home
Sweet and salty
Tears of joy
Liquid lies
Cheeks on fire
Loud and noisy
Girls and boys
Ancient rites
Late at night
Counting every second
We refuse to go
Counting every second
We will never dieThe earth is shaking
Down below our feet
We move in wonder
And we generate the beat
Our blood is boiling
Wonderful in heat
We glow like embers
Dancing in the dark
Where is the promised land
Where is the brave new world
Where do all dreams go when they die
We can move the streets today
The lights are fading out
Before our eyes
We lose each other
And we celebrate the peace
Our lives are changing
Faster than we think
We flow like dancers
Crashing in the dark
Another morning broken
Shattered sheets of lead
Clouds the size of oceans
Inside and above our heads
Ladies and gentlemen lights are going out let's step outside and watch the city sleep
Listen and remember wait another day we are explorers far away from home
Stay for just a moment watch the natives dance be civilized and kiss the pretty bride
Brothers and sisters the pain is gone for now let's burn our books and find a little peace
Sooner or later we walk another day we are colliders everywhere we go
Stay for just a car-crash know your heart is weak be primitive and wave your love goodbye
Ladies and gentlemen lights are going out let's step outside and watch the city sleep
Preachers and sinners we are all the same let's save ourselves and drink from deeper wells
Hatred and compassion wail against the walls we are invaders trying to escape
Fight for just a lifetime count the moments lost be so alive and cry as time goes by
Ladies and gentlemen lights are going out let's step outside and watch the city sleep
Greater than the sun
We are greater than the sun
I don't love anyone
No I just want my fun
I'm a happy man
Yes I'm a happy man
I'm falling out of cars
Don't know when I'll hit the ground
Hold me when I fall
Headlights in my face
My body's full of scars
Words are lost and won't be found
Stay until I'm gone
Stumbling on my knees
I'm dancing in the dark
Shrinking cities feel the sound
Hear the silent hum
Searchlights in the skies
I'm blinded by the stars
There is darkness all around
Hold me when I cry
Those were all my days
I'm falling out of cars
Hanging on the windscreen
Blinded by the headlights
I'm killing ground (we're covering ground)
I'm dancing in the dark
Stumbling on the highway
Guided by the city light
I'm lost and found
I'm falling out of cars
Don't know when I'll hit the ground
Hold me when I fall
Headlights in my face
I'm dancing in the dark
Shrinking cities feel the sound
Hear the distant hum
Searchlights in my eyes
I never took the time
I should have told you then
I never found the time
We make ritual noise
Wired to the world
Under our fingertips
We take special care
Listen to the words
Spoken in confidence
We make ritual noise
Shouting to be heard
Cooling our burning lips
We break down the gates
Open up our wounds
Bleeding for innocence
We make ritual noise
We weave the fabric of dreams
We build cities of sound
We feel the rhythm of time
We live dangerous lives
We have the power of will
We twist logic around
We feed the engines of change
I don't know how I ended up here
On this frozen nameless shore
I remember nothing of the journey
And there is no one else around
I go down across the towering dunes
To watch the seagulls glide above
So graceful when they are silent
Like lonely white ghosts in the air
I notice they are all unique
With faces that are all their own
Born to kiss the turbulent sky
Before they collapse and die
As I look and dream myself away
A sound grows loud enough to hear
Like disembodied friendly voices
Carried on by southbound winds
I wake up to the sound of silence
Their words are faint and far away
Like the finest spray of water
They still speak of things I know
I turn to fix my eyes on the horizon
And I face the freezing gale
I observe the majestic white waves
As they rise and break and fall
While they rise into the wild wind
It picks them up before it strikes
Steals away their urgent faces
Lifts their spirits to the skies
And their language's soft and broken
But still I understand it well
We talk about the ones we care for
And of all the things we lost
We are the men
Silent and cold
Beautiful eyes
Sheep among wolves
We are the men
Silent and strong
Beautiful eyes
Sheep among wolves
The world is growing loud
It's time for us to fade
To grey
I wish they'll let us stay
The lights are going out
We knew we had to go
One day
I wish they'll take us in
The skies are falling down
Too late for us to change
Our minds
I wish they'll keep us safe
The times are changing fast
We knew we wouldn't last
This long
I hope they'll keep the pace
The world is growing loud
It's time for us to fade
Away
I wish they'll let us stay
